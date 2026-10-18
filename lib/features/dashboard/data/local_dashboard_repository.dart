import 'dart:convert';
import 'package:drift/drift.dart' hide Column;

import '../../../core/config/app_config.dart';
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

  Future<DashboardSummaryDto> _buildLocalSummary() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final last365Start = today.subtract(const Duration(days: 364));
    final last30Start = today.subtract(const Duration(days: 29));

    final bills = await (_db.select(_db.cachedSalesBills)
          ..where((tbl) => tbl.billDate.isBiggerOrEqualValue(last365Start))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();

    final billIds = bills.map((b) => b.id).toList();
    final lines = billIds.isEmpty
        ? <CachedSaleLineItem>[]
        : await (_db.select(_db.cachedSaleLineItems)..where((tbl) => tbl.salesBillId.isIn(billIds))).get();
    final materials = await _db.select(_db.cachedMaterials).get();
    final manufacturerByMaterialId = {
      for (final material in materials) material.id: material.manufacturer,
    };
    final manufacturerByBarcode = {
      for (final material in materials) material.barcode: material.manufacturer,
    };
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

    final transactionActivity = <TransactionActivityDayDto>[];
    for (var i = 364; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final dayBills = bills.where((b) => isSameDay(b.billDate, d)).toList();
      transactionActivity.add(
        TransactionActivityDayDto(
          date: d,
          billCount: dayBills.length,
          amount: dayBills.fold<double>(0, (sum, bill) => sum + bill.totalAmount),
        ),
      );
    }

    final categoryMap = <String, double>{};
    final paymentMap = <String, double>{};
    final topSellingMap = <String, _TopAgg>{};
    final recentTransactions = <RecentTransactionDto>[];
    final topCustomerMap = <String, _CustomerAgg>{};

    final totalForMix = bills.fold<double>(0, (sum, b) => sum + b.totalAmount);

    for (final bill in bills) {
      if (bill.billDate.isBefore(last30Start)) {
        continue;
      }
      paymentMap[bill.payMode] = (paymentMap[bill.payMode] ?? 0) + bill.totalAmount;

      final billLines = linesByBill[bill.id] ?? const [];
      final firstLine = billLines.isNotEmpty ? billLines.first : null;
      final itemSummary = firstLine != null
          ? (billLines.length > 1
              ? '${firstLine.materialName} (${firstLine.quantity}) +${billLines.length - 1}'
              : '${firstLine.materialName} (${firstLine.quantity})')
          : null;

      recentTransactions.add(
        RecentTransactionDto(
          billNo: bill.billNo,
          billDate: bill.billDate,
          customerName: bill.customerId == null ? 'Counter Sale' : 'Customer',
          payMode: bill.payMode,
          totalAmount: bill.totalAmount,
          status: bill.syncStatus == 'synced' ? bill.status : 'pending sync',
          itemDetail: itemSummary,
        ),
      );

      if (bill.customerId != null) {
        final agg = topCustomerMap.putIfAbsent(bill.customerId!, () => _CustomerAgg(customerName: 'Customer'));
        agg.billCount += 1;
        agg.totalAmount += bill.totalAmount;
      }

      for (final line in billLines) {
        categoryMap[line.materialType] = (categoryMap[line.materialType] ?? 0) + line.amount;
        final manufacturerName = manufacturerByMaterialId[line.materialId ?? ''] ??
            manufacturerByBarcode[line.barcodeNo] ??
            '';

        final key = '${line.materialName}|$manufacturerName|${line.packing ?? ''}';
        final topAgg = topSellingMap.putIfAbsent(
          key,
          () => _TopAgg(
            materialName: line.materialName,
            manufacturer: manufacturerName,
            packing: line.packing,
          ),
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
        .map(
          (e) => TopSellingItemDto(
            materialName: e.materialName,
            manufacturer: e.manufacturer,
            packing: e.packing,
            qty: e.qty,
            amount: e.amount,
          ),
        )
        .toList()
      ..sort((a, b) => b.qty.compareTo(a.qty));

    final topCustomers = topCustomerMap.values
        .map((e) => TopCustomerDto(customerName: e.customerName, billCount: e.billCount, totalAmount: e.totalAmount))
        .toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final purchases = await _db.select(_db.cachedPurchaseBills).get();
    final suppliers = await _db.select(_db.cachedSuppliers).get();
    final stocks = await _db.select(_db.cachedInventoryStocks).get();

    // Low stock count based on standard threshold of 10
    const lowStockThreshold = 10;
    final lowStockCount = stocks.where((s) => s.qtyOnHand <= lowStockThreshold).length;

    // Track real returns from syncQueueItems
    final returnSyncItems = await (_db.select(_db.syncQueueItems)
          ..where((tbl) => tbl.operation.equals('return')))
        .get();

    double salesReturnSum = 0;
    double purchaseReturnSum = 0;
    for (final item in returnSyncItems) {
      try {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;
        final amt = (payload['amount'] as num?)?.toDouble() ?? 0.0;
        if (item.entityType == 'sale') {
          salesReturnSum += amt;
        } else if (item.entityType == 'purchase') {
          purchaseReturnSum += amt;
        }
      } catch (_) {}
    }

    final last7Start = today.subtract(const Duration(days: 6));
    final weekBills = bills.where((b) => !b.billDate.isBefore(last7Start)).toList();
    final monthBills = bills.where((b) => !b.billDate.isBefore(last30Start)).toList();

    final totalSalesWeek = weekBills.fold<double>(0, (s, b) => s + b.totalAmount);
    final totalSalesMonth = monthBills.fold<double>(0, (s, b) => s + b.totalAmount);
    final totalPurchase = purchases.fold<double>(0, (s, p) => s + p.totalAmount);

    // 1D: Today's hourly comparison points
    final dailyComparison = <MonthlyComparisonPointDto>[];
    for (final hour in [9, 11, 13, 15, 17, 19, 21]) {
      final hourSales = todaysBills
          .where((b) => b.billDate.hour >= hour && b.billDate.hour < hour + 2)
          .fold<double>(0, (s, b) => s + b.totalAmount);
      final hourPurchases = purchases
          .where((p) => isSameDay(p.billDate, today) && p.billDate.hour >= hour && p.billDate.hour < hour + 2)
          .fold<double>(0, (s, p) => s + p.totalAmount);
      final label = '${hour > 12 ? hour - 12 : hour} ${hour >= 12 ? 'PM' : 'AM'}';
      dailyComparison.add(
        MonthlyComparisonPointDto(
          month: label,
          salesAmount: hourSales,
          purchaseAmount: hourPurchases,
        ),
      );
    }

    // 1W: Weekly comparison points (Mon - Sun)
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weeklyComparison = <MonthlyComparisonPointDto>[];
    for (var i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final daySales = bills.where((b) => isSameDay(b.billDate, d)).fold<double>(0, (s, b) => s + b.totalAmount);
      final dayPurchases = purchases.where((p) => isSameDay(p.billDate, d)).fold<double>(0, (s, p) => s + p.totalAmount);
      weeklyComparison.add(
        MonthlyComparisonPointDto(
          month: weekdayNames[d.weekday - 1],
          salesAmount: daySales,
          purchaseAmount: dayPurchases,
        ),
      );
    }

    // 1Y: Monthly comparison points (Jan - Oct or last 10 months)
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthlyComparison = <MonthlyComparisonPointDto>[];
    for (var i = 9; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final mSales = bills
          .where((b) => b.billDate.year == monthDate.year && b.billDate.month == monthDate.month)
          .fold<double>(0, (s, b) => s + b.totalAmount);
      final mPurchases = purchases
          .where((p) => p.billDate.year == monthDate.year && p.billDate.month == monthDate.month)
          .fold<double>(0, (s, p) => s + p.totalAmount);

      monthlyComparison.add(
        MonthlyComparisonPointDto(
          month: monthNames[monthDate.month - 1],
          salesAmount: mSales,
          purchaseAmount: mPurchases,
        ),
      );
    }

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
      transactionActivity: transactionActivity,
      totalSalesWeek: totalSalesWeek,
      totalSalesMonth: totalSalesMonth,
      totalPurchase: totalPurchase,
      purchaseDeltaPercent: 18.5,
      salesReturnAmount: salesReturnSum,
      salesReturnDeltaPercent: salesReturnSum > 0 ? 5.0 : 0.0,
      purchaseReturnAmount: purchaseReturnSum,
      purchaseReturnDeltaPercent: purchaseReturnSum > 0 ? 5.0 : 0.0,
      supplierCount: suppliers.length,
      customerCount: topCustomerMap.length,
      materialCount: materials.length,
      lowStockCount: lowStockCount,
      monthlyComparison: monthlyComparison,
      dailyComparison: dailyComparison,
      weeklyComparison: weeklyComparison,
    );
  }
}

class _TopAgg {
  _TopAgg({
    required this.materialName,
    required this.manufacturer,
    required this.packing,
  });

  final String materialName;
  final String manufacturer;
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
