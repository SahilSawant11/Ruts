import 'package:drift/drift.dart';

import '../../../core/local/app_database.dart';

/// What moved in a date range, with every return counted on the day it
/// happened, never on the original bill's day. A day's figures therefore
/// never change after that day (the excise registers depend on it).
///
///  - [sold]: bottles on sale bills dated in the range, as they were sold,
///    including bills returned later.
///  - [salesReturned]: bottles customers brought back in the range, whatever
///    day their bill was made.
///  - [bought] / [purchaseReturned]: the same for purchases and goods sent
///    back to the distributor.
///
/// "As sold" is rebuilt from the bill: a partial return shrinks (or
/// removes) the bill's line, so the line's current quantity plus its
/// partial-return entries is what was on the bill. A full return leaves the
/// lines untouched, so its entries are not added back.
class StockMovements {
  final sold = <String, int>{};
  final salesReturned = <String, int>{};
  final bought = <String, int>{};
  final purchaseReturned = <String, int>{};

  /// Per material, the purchase rows of the range in time order: (TP, qty).
  /// Goods sent back in the range are negative rows under the TP they came on.
  final tpRows = <String, List<(String?, int)>>{};

  /// The TP numbers of the range in the order they happened.
  final tpOrder = <String>[];

  int netSale(String id) => (sold[id] ?? 0) - (salesReturned[id] ?? 0);
  int netPurchase(String id) => (bought[id] ?? 0) - (purchaseReturned[id] ?? 0);

  Set<String> get materialIds => {...sold.keys, ...salesReturned.keys, ...bought.keys, ...purchaseReturned.keys};
}

/// Movements in [start, end).
Future<StockMovements> stockMovements(AppDatabase db, DateTime start, DateTime end) async {
  final m = StockMovements();
  final range = [Variable.withDateTime(start), Variable.withDateTime(end)];

  Future<void> sumInto(Map<String, int> into, String sql) async {
    for (final r in await db.customSelect(sql, variables: range).get()) {
      final id = r.readNullable<String>('id') ?? '';
      if (id.isEmpty) continue;
      into[id] = (into[id] ?? 0) + r.read<int>('q');
    }
  }

  // Sales, on the bill's day, as sold.
  await sumInto(m.sold, '''
    SELECT l.material_id AS id, SUM(l.quantity) AS q
    FROM cached_sale_line_items l JOIN cached_sales_bills b ON b.id = l.sales_bill_id
    WHERE b.bill_date >= ? AND b.bill_date < ? GROUP BY l.material_id''');
  await sumInto(m.sold, '''
    SELECT e.material_id AS id, SUM(e.quantity) AS q
    FROM sales_return_entries e JOIN cached_sales_bills b ON b.id = e.sales_bill_id
    WHERE e.is_full_bill_return = 0 AND b.bill_date >= ? AND b.bill_date < ? GROUP BY e.material_id''');
  // Sales returns, on the return day.
  await sumInto(m.salesReturned, '''
    SELECT material_id AS id, SUM(quantity) AS q FROM sales_return_entries
    WHERE returned_at >= ? AND returned_at < ? GROUP BY material_id''');

  // Purchases, on the bill's day, as received, per TP in time order.
  final events = <(DateTime, String?, String, int)>[]; // when, TP, material, qty
  for (final r in await db.customSelect('''
    SELECT b.bill_date AS at, b.tp_no AS tp, l.material_id AS id, SUM(l.qty) AS q
    FROM cached_purchase_line_items l JOIN cached_purchase_bills b ON b.id = l.purchase_bill_id
    WHERE b.bill_date >= ? AND b.bill_date < ? GROUP BY b.id, l.material_id''', variables: range).get()) {
    events.add((r.read<DateTime>('at'), r.readNullable<String>('tp'), r.read<String>('id'), r.read<int>('q')));
  }
  for (final r in await db.customSelect('''
    SELECT b.bill_date AS at, b.tp_no AS tp, e.material_id AS id, SUM(e.quantity) AS q
    FROM purchase_return_entries e JOIN cached_purchase_bills b ON b.id = e.purchase_bill_id
    WHERE e.is_full_bill_return = 0 AND b.bill_date >= ? AND b.bill_date < ?
    GROUP BY b.id, e.material_id''', variables: range).get()) {
    events.add((r.read<DateTime>('at'), r.readNullable<String>('tp'), r.read<String>('id'), r.read<int>('q')));
  }
  // Goods sent back, on the day they went back.
  for (final r in await db.customSelect('''
    SELECT e.returned_at AS at, b.tp_no AS tp, e.material_id AS id, SUM(e.quantity) AS q
    FROM purchase_return_entries e JOIN cached_purchase_bills b ON b.id = e.purchase_bill_id
    WHERE e.returned_at >= ? AND e.returned_at < ?
    GROUP BY e.returned_at, b.id, e.material_id''', variables: range).get()) {
    final q = r.read<int>('q');
    events.add((r.read<DateTime>('at'), r.readNullable<String>('tp'), r.read<String>('id'), -q));
    m.purchaseReturned[r.read<String>('id')] = (m.purchaseReturned[r.read<String>('id')] ?? 0) + q;
  }
  events.sort((a, b) {
    final byTime = a.$1.compareTo(b.$1);
    return byTime != 0 ? byTime : (a.$2 ?? '').compareTo(b.$2 ?? '');
  });
  for (final (_, tp, id, q) in events) {
    if (q > 0) m.bought[id] = (m.bought[id] ?? 0) + q;
    m.tpRows.putIfAbsent(id, () => []).add((tp, q));
    final key = tp?.trim() ?? '';
    if (!m.tpOrder.contains(key)) m.tpOrder.add(key);
  }
  // Received and partially sent back on the bill's day: the received rows
  // above already add the partial entries back, so [bought] is as received.
  return m;
}
