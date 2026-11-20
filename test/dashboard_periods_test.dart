// Dashboard periods: Today / 7 days / 30 days / 12 months each count the
// right bills, compare with the equally long period before, and leave out
// fully returned bills.
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
  final now = DateTime(2026, 11, 20, 15, 0);

  setUp(() async {
    env = await TestEnv.create(fileBacked: false);
    dash = LocalDashboardRepository(env.db, DashboardApiRepository(http.Client()), env.sales);
    await env.addMaterial('A', stock: 1000);
  });
  tearDown(() async => env.dispose());

  /// A bill of [amount] (bottles × ₹1) dated [daysAgo] days before [now].
  Future<String> billOn(int daysAgo, int amount, {int hour = 12}) async {
    final r = await env.sales.createSale(TestEnv.sale({'A': amount}, rate: 1));
    final date = DateTime(now.year, now.month, now.day - daysAgo, hour);
    await (env.db.update(env.db.cachedSalesBills)..where((t) => t.id.equals(r.id)))
        .write(CachedSalesBillsCompanion(billDate: Value(date)));
    return r.id;
  }

  test('each period counts its own days and compares with the one before', () async {
    await billOn(0, 1, hour: 0); // today, just after midnight
    await billOn(0, 2, hour: 23); // today, late night
    await billOn(6, 4); // last day inside 7 days
    await billOn(7, 8); // previous 7 days
    await billOn(29, 16); // last day inside 30 days
    await billOn(30, 32); // previous 30 days
    await billOn(365 - 1, 64); // last day inside 12 months
    await billOn(365, 128); // previous 12 months
    await billOn(1, 256); // yesterday

    Future<(double, double, double)> sales(DashboardPeriod p) async {
      final s = await dash.getPeriodSnapshot(p, now: now);
      return (s.sales.current, s.sales.previous, s.billCount.current);
    }

    expect(await sales(DashboardPeriod.today), (3.0, 256.0, 2.0));
    expect(await sales(DashboardPeriod.week), (1 + 2 + 4 + 256.0, 8 + 0.0, 4.0));
    expect(await sales(DashboardPeriod.month), (1 + 2 + 4 + 8 + 16 + 256.0, 32.0, 6.0));
    expect(await sales(DashboardPeriod.year), (1 + 2 + 4 + 8 + 16 + 32 + 64 + 256.0, 128.0, 8.0));
  });

  test('a fully returned bill counts as a return, not a sale', () async {
    await billOn(0, 5);
    final gone = await billOn(0, 7);
    await env.sales.returnSalesBill(gone);
    final s = await dash.getPeriodSnapshot(DashboardPeriod.today, now: DateTime.now());
    expect(s.sales.current, 5);
    expect(s.billCount.current, 1);
    expect(s.salesReturns.current, 7, reason: 'returned today');
  });

  test('no previous sales shows "—", not an invented percentage', () async {
    await billOn(0, 5);
    final s = await dash.getPeriodSnapshot(DashboardPeriod.week, now: now);
    expect(s.sales.deltaPercent, isNull);
  });
}
