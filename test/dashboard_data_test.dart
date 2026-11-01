import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/features/dashboard/data/dashboard_api_repository.dart';
import 'package:pos_app/features/dashboard/data/local_dashboard_repository.dart';
import 'package:pos_app/features/dashboard/data/models/dashboard_summary_dto.dart';

import 'support/test_env.dart';

void main() {
  late TestEnv env;
  late LocalDashboardRepository dash;

  setUp(() async {
    env = await TestEnv.create();
    dash = LocalDashboardRepository(env.db, DashboardApiRepository(http.Client()), env.sales);
    await env.addMaterial('A', stock: 100);
    await env.addMaterial('B', stock: 100);
  });
  tearDown(() async => env.dispose());

  Future<void> backdate(String billId, DateTime when) async {
    await (env.db.update(env.db.cachedSalesBills)..where((t) => t.id.equals(billId)))
        .write(CachedSalesBillsCompanion(billDate: Value(when), createdAt: Value(when)));
  }

  test('today vs yesterday uses real sales and returns, excludes returned bills', () async {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1, 12);

    final y = await env.sales.createSale(TestEnv.sale({'A': 4})); // 400 yesterday
    await backdate(y.id, yesterday);

    await env.sales.createSale(TestEnv.sale({'A': 3})); // 300 today
    final back = await env.sales.createSale(TestEnv.sale({'B': 2})); // 200, fully returned
    await env.sales.returnSalesBill(back.id);

    final s = await dash.getPeriodSnapshot(DashboardPeriod.today);
    expect(s.sales.current, 300);
    expect(s.sales.previous, 400);
    expect(s.sales.deltaPercent, closeTo(-25, 0.001));
    expect(s.billCount.current, 1);
    expect(s.salesReturns.current, 200);
    expect(s.salesReturns.deltaPercent, isNull, reason: 'nothing to compare with → no invented %');
    expect(s.purchases.current, 0);
    expect(s.topSellingItems.single.materialName, 'Item A');
    expect(s.categoryBreakdown.single.amount, 300);
  });

  test('summary has no sample data on an empty store', () async {
    final summary = await dash.getSummary();
    expect(summary.recentTransactions, isEmpty);
    expect(summary.topSellingItems, isEmpty);
    expect(summary.monthlyComparison.every((p) => p.salesAmount == 0), isTrue);
    expect(summary.last4WeeksComparison, hasLength(4));
    expect(summary.transactionActivity, hasLength(365));
    expect(summary.lowStockCount, 0);
  });

  test('low stock follows each item\'s reorder level', () async {
    await (env.db.update(env.db.cachedInventoryStocks)..where((t) => t.materialId.equals('A')))
        .write(const CachedInventoryStocksCompanion(qtyOnHand: Value(30), reorderLevel: Value(50)));
    final summary = await dash.getSummary();
    expect(summary.lowStockCount, 1);
  });
}
