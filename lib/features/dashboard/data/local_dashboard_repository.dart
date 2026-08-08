import 'package:drift/drift.dart' hide Column;

import '../../../core/local/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../sales/data/local_sales_repository.dart';
import 'dashboard_api_repository.dart';
import 'models/dashboard_summary_dto.dart';

class LocalDashboardRepository {
  LocalDashboardRepository(this._db, this._remote, this._sales);

  final AppDatabase _db;
  final DashboardApiRepository _remote;
  final LocalSalesRepository _sales;

  Future<DashboardSummaryDto> getSummary() async {
    try {
      await _sales.syncPendingSales();
    } on ApiException {
      // Fall through to local summary below.
    }

    final local = await _buildLocalSummary();
    if (_hasLocalActivity(local)) return local;

    try {
      return await _remote.getSummary();
    } on ApiException {
      return local;
    }
  }

  bool _hasLocalActivity(DashboardSummaryDto summary) {
    return summary.todayBillCount > 0 ||
        summary.last7Days.any((p) => p.amount > 0) ||
        summary.recentTransactions.isNotEmpty ||
        summary.topSellingItems.isNotEmpty;
  }

  Future<DashboardSummaryDto> _buildLocalSummary() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final last30Start = today.subtract(const Duration(days: 29));

    final bills = await (_db.select(_db.cachedSalesBills)
          ..where((tbl) => tbl.billDate.isBiggerOrEqualValue(last30Start))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();

    final billIds = bills.map((b) => b.id).toList();
    final lines = billIds.isEmpty
        ? <CachedSaleLineItem>[]
        : await (_db.select(_db.cachedSaleLineItems)..where((tbl) => tbl.salesBillId.isIn(billIds))).get();
    final linesByBill = <String, List<CachedSaleLineItem>>{};
    for (final line in lines) {
      linesByBill.putIfAbsent(line.salesBillId, () => []).add(line);
    }

    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final todaysBills = bills.where((b) => isSameDay(b.billDate, today)).toList();
    final yesterdaysBills = bills.where((b) => isSameDay(b.billDate, yesterday)).toList();

    final todaySales = todaysBills.fold<double>(0, (sum, b) => sum + b.totalAmount);
    final yesterdaySales = yesterdaysBills.fold<double>(0, (sum, b) => sum + b.totalAmount);
    final todayBillCount = todaysBills.length;
    final yesterdayBillCount = yesterdaysBills.length;
    final avgBillValue = todayBillCount > 0 ? todaySales / todayBillCount : 0.0;

    double? salesDeltaPercent = yesterdaySales > 0 ? ((todaySales - yesterdaySales) / yesterdaySales) * 100 : null;
    double? billsDeltaPercent =
        yesterdayBillCount > 0 ? ((todayBillCount - yesterdayBillCount) / yesterdayBillCount) * 100 : null;

    final last7Days = <DailyTrendPointDto>[];
    for (var i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final amount = bills.where((b) => isSameDay(b.billDate, d)).fold<double>(0, (sum, b) => sum + b.totalAmount);
      last7Days.add(DailyTrendPointDto(date: d, amount: amount));
    }

    final categoryMap = <String, double>{};
    final paymentMap = <String, double>{};
    final topSellingMap = <String, _TopAgg>{};
    final recentTransactions = <RecentTransactionDto>[];
    final topCustomerMap = <String, _CustomerAgg>{};

    final totalForMix = bills.fold<double>(0, (sum, b) => sum + b.totalAmount);

    for (final bill in bills) {
      paymentMap[bill.payMode] = (paymentMap[bill.payMode] ?? 0) + bill.totalAmount;

      recentTransactions.add(
        RecentTransactionDto(
          billNo: bill.billNo,
          billDate: bill.billDate,
          customerName: bill.customerId == null ? 'Counter Sale' : 'Customer',
          payMode: bill.payMode,
          totalAmount: bill.totalAmount,
          status: bill.syncStatus == 'synced' ? bill.status : 'pending sync',
        ),
      );

      if (bill.customerId != null) {
        final agg = topCustomerMap.putIfAbsent(bill.customerId!, () => _CustomerAgg(customerName: 'Customer'));
        agg.billCount += 1;
        agg.totalAmount += bill.totalAmount;
      }

      final billLines = linesByBill[bill.id] ?? const [];
      for (final line in billLines) {
        categoryMap[line.materialType] = (categoryMap[line.materialType] ?? 0) + line.amount;

        final key = '${line.materialName}|${line.packing ?? ''}';
        final topAgg = topSellingMap.putIfAbsent(
          key,
          () => _TopAgg(materialName: line.materialName, packing: line.packing),
        );
        topAgg.qty += line.quantity;
        topAgg.amount += line.amount;
      }
    }

    final categoryBreakdown = categoryMap.entries
        .map((e) => CategoryBreakdownItemDto(category: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final paymentMix = paymentMap.entries
        .map(
          (e) => PaymentMixItemDto(
            payMode: e.key,
            amount: e.value,
            percent: totalForMix > 0 ? (e.value / totalForMix) * 100 : 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final topSellingItems = topSellingMap.values
        .map((e) => TopSellingItemDto(materialName: e.materialName, packing: e.packing, qty: e.qty, amount: e.amount))
        .toList()
      ..sort((a, b) => b.qty.compareTo(a.qty));

    final topCustomers = topCustomerMap.values
        .map((e) => TopCustomerDto(customerName: e.customerName, billCount: e.billCount, totalAmount: e.totalAmount))
        .toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    recentTransactions.sort((a, b) => b.billDate.compareTo(a.billDate));

    return DashboardSummaryDto(
      todaySales: todaySales,
      todayBillCount: todayBillCount,
      avgBillValue: avgBillValue,
      salesDeltaPercent: salesDeltaPercent,
      billsDeltaPercent: billsDeltaPercent,
      dailyTarget: 250000.0,
      last7Days: last7Days,
      categoryBreakdown: categoryBreakdown,
      paymentMix: paymentMix,
      topSellingItems: topSellingItems.take(5).toList(),
      recentTransactions: recentTransactions.take(8).toList(),
      topCustomers: topCustomers.take(5).toList(),
    );
  }
}

class _TopAgg {
  _TopAgg({required this.materialName, required this.packing});

  final String materialName;
  final String? packing;
  int qty = 0;
  double amount = 0;
}

class _CustomerAgg {
  _CustomerAgg({required this.customerName});

  final String customerName;
  int billCount = 0;
  double totalAmount = 0;
}
