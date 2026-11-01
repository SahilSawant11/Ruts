import 'package:drift/drift.dart' hide Column;

import '../../../core/config/app_config.dart';
import '../../../core/local/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../sales/data/local_sales_repository.dart';
import 'dashboard_api_repository.dart';
import 'models/dashboard_summary_dto.dart';

/// Builds dashboard figures straight from SQLite with aggregate queries,
/// so cost stays flat as years of bills accumulate.
///
/// Every number is real: fully returned bills are excluded (as in the
/// reports), returns come from the return audit tables, and a trend is
/// only shown when the previous period has data to compare against.
class LocalDashboardRepository {
  LocalDashboardRepository(this._db, this._remote, this._sales);

  final AppDatabase _db;
  final DashboardApiRepository _remote;
  final LocalSalesRepository _sales;

  static const _activeSale = "b.status <> 'returned'";
  static const _activePurchase = 'p.returned_at IS NULL';
  static const _localDay = "date(b.bill_date, 'unixepoch', 'localtime')";

  Future<DashboardSummaryDto> getSummary() async {
    if (AppConfig.offlineOnly) return _buildLocalSummary();

    try {
      await _sales.syncPendingSales();
    } on ApiException {
      // Fall through to local summary below.
    }

    try {
      return await _remote.getSummary();
    } on ApiException {
      return _buildLocalSummary();
    }
  }

  // ── Period snapshot (KPIs, categories, top products, payment mix) ────

  Future<DashboardPeriodSnapshot> getPeriodSnapshot(DashboardPeriod period, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final (start, end) = period.range(at);
    final (prevStart, prevEnd) = period.previousRange(at);

    Future<PeriodMetric> metric(Future<double> Function(DateTime, DateTime) f) async =>
        PeriodMetric(await f(start, end), await f(prevStart, prevEnd));

    return DashboardPeriodSnapshot(
      period: period,
      sales: await metric(_salesTotal),
      billCount: await metric(_billCount),
      salesReturns: await metric((s, e) => _sum('sales_return_entries', 'amount', 'returned_at', s, e)),
      purchases: await metric(_purchaseTotal),
      purchaseReturns: await metric((s, e) => _sum('purchase_return_entries', 'amount', 'returned_at', s, e)),
      categoryBreakdown: await _categories(start, end),
      topSellingItems: await _topSelling(start, end),
      paymentMix: await _paymentMix(start, end),
    );
  }

  Future<double> _salesTotal(DateTime s, DateTime e) async {
    final r = await _db.customSelect(
      'SELECT COALESCE(SUM(b.total_amount), 0) AS v FROM cached_sales_bills b '
      'WHERE $_activeSale AND b.bill_date >= ? AND b.bill_date < ?',
      variables: [Variable.withDateTime(s), Variable.withDateTime(e)],
    ).getSingle();
    return r.read<double>('v');
  }

  Future<double> _billCount(DateTime s, DateTime e) async {
    final r = await _db.customSelect(
      'SELECT COUNT(*) AS v FROM cached_sales_bills b WHERE $_activeSale AND b.bill_date >= ? AND b.bill_date < ?',
      variables: [Variable.withDateTime(s), Variable.withDateTime(e)],
    ).getSingle();
    return r.read<int>('v').toDouble();
  }

  Future<double> _purchaseTotal(DateTime s, DateTime e) async {
    final r = await _db.customSelect(
      'SELECT COALESCE(SUM(p.total_amount), 0) AS v FROM cached_purchase_bills p '
      'WHERE $_activePurchase AND p.bill_date >= ? AND p.bill_date < ?',
      variables: [Variable.withDateTime(s), Variable.withDateTime(e)],
    ).getSingle();
    return r.read<double>('v');
  }

  Future<double> _sum(String table, String column, String dateColumn, DateTime s, DateTime e) async {
    final r = await _db.customSelect(
      'SELECT COALESCE(SUM($column), 0) AS v FROM $table WHERE $dateColumn >= ? AND $dateColumn < ?',
      variables: [Variable.withDateTime(s), Variable.withDateTime(e)],
    ).getSingle();
    return r.read<double>('v');
  }

  Future<List<CategoryBreakdownItemDto>> _categories(DateTime s, DateTime e) async {
    final rows = await _db.customSelect(
      'SELECT l.material_type AS category, SUM(l.amount) AS amount '
      'FROM cached_sale_line_items l JOIN cached_sales_bills b ON b.id = l.sales_bill_id '
      'WHERE $_activeSale AND b.bill_date >= ? AND b.bill_date < ? '
      'GROUP BY l.material_type ORDER BY amount DESC',
      variables: [Variable.withDateTime(s), Variable.withDateTime(e)],
    ).get();
    return [
      for (final r in rows)
        CategoryBreakdownItemDto(category: r.read<String>('category'), amount: r.read<double>('amount')),
    ];
  }

  Future<List<TopSellingItemDto>> _topSelling(DateTime s, DateTime e, {int limit = 5}) async {
    final rows = await _db.customSelect(
      'SELECT l.material_name AS name, l.packing AS packing, '
      "COALESCE(MAX(m.manufacturer), '') AS manufacturer, "
      'SUM(l.quantity) AS qty, SUM(l.amount) AS amount '
      'FROM cached_sale_line_items l JOIN cached_sales_bills b ON b.id = l.sales_bill_id '
      'LEFT JOIN cached_materials m ON m.id = l.material_id '
      'WHERE $_activeSale AND b.bill_date >= ? AND b.bill_date < ? '
      'GROUP BY l.material_name, l.packing ORDER BY qty DESC, amount DESC LIMIT ?',
      variables: [Variable.withDateTime(s), Variable.withDateTime(e), Variable.withInt(limit)],
    ).get();
    return [
      for (final r in rows)
        TopSellingItemDto(
          materialName: r.read<String>('name'),
          manufacturer: r.read<String>('manufacturer'),
          packing: r.readNullable<String>('packing'),
          qty: r.read<int>('qty'),
          amount: r.read<double>('amount'),
        ),
    ];
  }

  Future<List<PaymentMixItemDto>> _paymentMix(DateTime s, DateTime e) async {
    final rows = await _db.customSelect(
      'SELECT b.pay_mode AS mode, SUM(b.total_amount) AS amount FROM cached_sales_bills b '
      'WHERE $_activeSale AND b.bill_date >= ? AND b.bill_date < ? GROUP BY b.pay_mode ORDER BY amount DESC',
      variables: [Variable.withDateTime(s), Variable.withDateTime(e)],
    ).get();
    final total = rows.fold<double>(0, (t, r) => t + r.read<double>('amount'));
    return [
      for (final r in rows)
        PaymentMixItemDto(
          payMode: r.read<String>('mode'),
          amount: r.read<double>('amount'),
          percent: total > 0 ? r.read<double>('amount') / total * 100 : 0,
        ),
    ];
  }

  // ── Period-independent summary (charts, heatmap, counts, recent) ─────

  Future<DashboardSummaryDto> _buildLocalSummary() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yearStart = DateTime(today.year, today.month, today.day - 364);

    // Daily sales totals + bill counts for the last 365 days, one query.
    final dailyRows = await _db.customSelect(
      'SELECT $_localDay AS day, COUNT(*) AS bills, SUM(b.total_amount) AS amount '
      'FROM cached_sales_bills b WHERE $_activeSale AND b.bill_date >= ? AND b.bill_date < ? GROUP BY day',
      variables: [Variable.withDateTime(yearStart), Variable.withDateTime(tomorrow)],
    ).get();
    final salesByDay = <String, (int, double)>{
      for (final r in dailyRows) r.read<String>('day'): (r.read<int>('bills'), r.read<double>('amount')),
    };

    final purchaseRows = await _db.customSelect(
      "SELECT date(p.bill_date, 'unixepoch', 'localtime') AS day, SUM(p.total_amount) AS amount "
      'FROM cached_purchase_bills p WHERE $_activePurchase AND p.bill_date >= ? AND p.bill_date < ? GROUP BY day',
      variables: [Variable.withDateTime(yearStart), Variable.withDateTime(tomorrow)],
    ).get();
    final purchasesByDay = <String, double>{
      for (final r in purchaseRows) r.read<String>('day'): r.read<double>('amount'),
    };

    String key(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final transactionActivity = <TransactionActivityDayDto>[];
    for (var i = 364; i >= 0; i--) {
      final d = DateTime(today.year, today.month, today.day - i);
      final (count, amount) = salesByDay[key(d)] ?? (0, 0.0);
      transactionActivity.add(TransactionActivityDayDto(date: d, billCount: count, amount: amount));
    }

    final last7Days = [
      for (var i = 6; i >= 0; i--)
        () {
          final d = DateTime(today.year, today.month, today.day - i);
          return DailyTrendPointDto(date: d, amount: salesByDay[key(d)]?.$2 ?? 0);
        }(),
    ];

    // 1D: today in two-hour buckets (sales use the exact bill time).
    final hourRows = await _db.customSelect(
      "SELECT CAST(strftime('%H', b.bill_date, 'unixepoch', 'localtime') AS INTEGER) AS h, SUM(b.total_amount) AS amount "
      'FROM cached_sales_bills b WHERE $_activeSale AND b.bill_date >= ? AND b.bill_date < ? GROUP BY h',
      variables: [Variable.withDateTime(today), Variable.withDateTime(tomorrow)],
    ).get();
    final salesByHour = {for (final r in hourRows) r.read<int>('h'): r.read<double>('amount')};
    final todayPurchases = purchasesByDay[key(today)] ?? 0;
    final dailyComparison = <MonthlyComparisonPointDto>[];
    for (final hour in const [9, 11, 13, 15, 17, 19, 21]) {
      final sales = (salesByHour[hour] ?? 0) + (salesByHour[hour + 1] ?? 0);
      final label = '${hour > 12 ? hour - 12 : hour} ${hour >= 12 ? 'PM' : 'AM'}';
      // Purchases are dated by day only, so today's total sits in the first bucket.
      dailyComparison.add(MonthlyComparisonPointDto(
        month: label,
        salesAmount: sales,
        purchaseAmount: hour == 9 ? todayPurchases : 0,
      ));
    }

    // 1W: last seven days.
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weeklyComparison = [
      for (var i = 6; i >= 0; i--)
        () {
          final d = DateTime(today.year, today.month, today.day - i);
          return MonthlyComparisonPointDto(
            month: weekdayNames[d.weekday - 1],
            salesAmount: salesByDay[key(d)]?.$2 ?? 0,
            purchaseAmount: purchasesByDay[key(d)] ?? 0,
          );
        }(),
    ];

    // 1M: four 7-day buckets ending today, labelled by their start date.
    const shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final last4WeeksComparison = <MonthlyComparisonPointDto>[];
    for (var w = 3; w >= 0; w--) {
      final weekStart = DateTime(today.year, today.month, today.day - w * 7 - 6);
      var sales = 0.0;
      var purchases = 0.0;
      for (var d = 0; d < 7; d++) {
        final day = DateTime(weekStart.year, weekStart.month, weekStart.day + d);
        sales += salesByDay[key(day)]?.$2 ?? 0;
        purchases += purchasesByDay[key(day)] ?? 0;
      }
      last4WeeksComparison.add(MonthlyComparisonPointDto(
        month: '${weekStart.day} ${shortMonths[weekStart.month - 1]}',
        salesAmount: sales,
        purchaseAmount: purchases,
      ));
    }

    // 1Y: last twelve months (including this one).
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final salesByMonth = <String, double>{};
    salesByDay.forEach((day, v) => salesByMonth[day.substring(0, 7)] = (salesByMonth[day.substring(0, 7)] ?? 0) + v.$2);
    final purchasesByMonth = <String, double>{};
    purchasesByDay
        .forEach((day, v) => purchasesByMonth[day.substring(0, 7)] = (purchasesByMonth[day.substring(0, 7)] ?? 0) + v);
    final monthlyComparison = [
      for (var i = 11; i >= 0; i--)
        () {
          final m = DateTime(now.year, now.month - i, 1);
          final k = key(m).substring(0, 7);
          return MonthlyComparisonPointDto(
            month: monthNames[m.month - 1],
            salesAmount: salesByMonth[k] ?? 0,
            purchaseAmount: purchasesByMonth[k] ?? 0,
          );
        }(),
    ];

    final (todayBills, todaySales) = salesByDay[key(today)] ?? (0, 0.0);
    final (yBills, ySales) = salesByDay[key(today.subtract(const Duration(days: 1)))] ?? (0, 0.0);

    final last30 = DateTime(today.year, today.month, today.day - 29);

    return DashboardSummaryDto(
      todaySales: todaySales,
      todayBillCount: todayBills,
      avgBillValue: todayBills > 0 ? todaySales / todayBills : 0,
      salesDeltaPercent: ySales > 0 ? (todaySales - ySales) / ySales * 100 : null,
      billsDeltaPercent: yBills > 0 ? (todayBills - yBills) / yBills * 100 : null,
      dailyTarget: 0,
      last7Days: last7Days,
      categoryBreakdown: await _categories(last30, tomorrow),
      paymentMix: await _paymentMix(last30, tomorrow),
      topSellingItems: await _topSelling(last30, tomorrow),
      recentTransactions: await _recentTransactions(),
      topCustomers: const [],
      transactionActivity: transactionActivity,
      supplierCount: await _count('cached_suppliers'),
      materialCount: await _count('cached_materials', where: 'is_active = 1'),
      lowStockCount: await _count('cached_inventory_stocks', where: 'qty_on_hand <= reorder_level'),
      monthlyComparison: monthlyComparison,
      dailyComparison: dailyComparison,
      weeklyComparison: weeklyComparison,
      last4WeeksComparison: last4WeeksComparison,
    );
  }

  Future<int> _count(String table, {String? where}) async {
    final r =
        await _db.customSelect('SELECT COUNT(*) AS c FROM $table${where == null ? '' : ' WHERE $where'}').getSingle();
    return r.read<int>('c');
  }

  Future<List<RecentTransactionDto>> _recentTransactions({int limit = 8}) async {
    final bills = await (_db.select(_db.cachedSalesBills)
          ..where(_db.isActiveSaleBill)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
    if (bills.isEmpty) return const [];
    final lines = await (_db.select(_db.cachedSaleLineItems)
          ..where((t) => t.salesBillId.isIn(bills.map((b) => b.id)))
          ..orderBy([(t) => OrderingTerm.asc(t.lineNumber)]))
        .get();
    final byBill = <String, List<CachedSaleLineItem>>{};
    for (final l in lines) {
      byBill.putIfAbsent(l.salesBillId, () => []).add(l);
    }
    return [
      for (final bill in bills)
        () {
          final billLines = byBill[bill.id] ?? const <CachedSaleLineItem>[];
          final first = billLines.isEmpty ? null : billLines.first;
          return RecentTransactionDto(
            billNo: bill.billNo,
            // createdAt carries the real time of sale (billDate may be date-only).
            billDate: bill.createdAt.toLocal(),
            customerName: bill.customerId == null ? 'Counter Sale' : 'Customer',
            payMode: bill.payMode,
            totalAmount: bill.totalAmount,
            status: bill.syncStatus == 'synced' ? bill.status : 'pending sync',
            itemDetail: first == null
                ? null
                : '${first.materialName} (${first.quantity})${billLines.length > 1 ? ' +${billLines.length - 1}' : ''}',
          );
        }(),
    ];
  }
}
