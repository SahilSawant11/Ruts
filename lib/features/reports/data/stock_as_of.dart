import 'package:drift/drift.dart';

import '../../../core/local/app_database.dart';

/// Stock on hand per product at [endExclusive] (the start of the day
/// after the report date), worked back from today's stock:
///
///   closing(day) = stock now + sold after the day − purchased after the day
///
/// Returns don't need their own term: a partial return reduces the
/// original bill line and a full return deactivates the bill, so counting
/// active bill lines already nets them out, exactly as the reports' own
/// sale and purchase columns do. For today this is just stock now.
Future<Map<String, int>> closingStockAsOf(AppDatabase db, DateTime endExclusive) async {
  final stock = {
    for (final s in await db.select(db.cachedInventoryStocks).get()) s.materialId: s.qtyOnHand,
  };

  final farFuture = DateTime(9999);
  final soldAfter = await (db.select(db.cachedSaleLineItems)
        ..where((t) => db.lineOfActiveBillBetween(t, endExclusive, farFuture)))
      .get();
  for (final line in soldAfter) {
    final id = line.materialId;
    if (id == null || id.isEmpty) continue;
    stock[id] = (stock[id] ?? 0) + line.quantity;
  }

  final laterBills = await (db.select(db.cachedPurchaseBills)
        ..where((t) => db.isActivePurchaseBill(t) & t.billDate.isBiggerOrEqualValue(endExclusive)))
      .get();
  if (laterBills.isNotEmpty) {
    final ids = laterBills.map((b) => b.id).toList();
    // Chunk to stay under SQLite's bound-variable limit on busy stores.
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
      final lines = await (db.select(db.cachedPurchaseLineItems)..where((t) => t.purchaseBillId.isIn(chunk))).get();
      for (final line in lines) {
        stock[line.materialId] = (stock[line.materialId] ?? 0) - line.qty;
      }
    }
  }
  return stock;
}
