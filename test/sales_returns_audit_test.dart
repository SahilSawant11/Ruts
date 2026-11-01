import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/core/network/api_exception.dart';
import 'package:pos_app/features/reports/data/local_reports_repository.dart';
import 'package:pos_app/features/reports/data/reports_api_repository.dart';

import 'support/test_env.dart';

void main() {
  late TestEnv env;
  late LocalReportsRepository reports;

  setUp(() async {
    env = await TestEnv.create();
    reports = LocalReportsRepository(env.db, ReportsApiRepository(http.Client()), env.sales);
    await env.addMaterial('A', stock: 50);
    await env.addMaterial('B', stock: 50);
  });
  tearDown(() async => env.dispose());

  Future<double> reportTotal() async {
    final now = DateTime.now();
    final r = await reports.getSalesReport(from: DateTime(now.year, now.month, now.day), to: now);
    return r.totalAmount;
  }

  test('full return keeps the bill, marks it returned, and reports exclude it', () async {
    final keep = await env.sales.createSale(TestEnv.sale({'A': 2}));
    final back = await env.sales.createSale(TestEnv.sale({'A': 1, 'B': 3}));
    expect(await reportTotal(), 600);

    await env.sales.returnSalesBill(back.id, returnedBy: 'cashier');

    final bill = await (env.db.select(env.db.cachedSalesBills)..where((t) => t.id.equals(back.id))).getSingle();
    expect(bill.status, AppDatabase.saleStatusReturned);
    expect(bill.returnedBy, 'cashier');
    expect(bill.returnedAt, isNotNull);
    expect(bill.totalAmount, 400, reason: 'original amounts kept for the record');
    final lines = await (env.db.select(env.db.cachedSaleLineItems)..where((t) => t.salesBillId.equals(back.id))).get();
    expect(lines.map((l) => l.quantity), [1, 3]);

    expect(await reportTotal(), 200, reason: 'same figure as when returns deleted the bill');
    expect(await env.stockOf('A'), 48);
    expect(await env.stockOf('B'), 50);

    final listed = await env.sales.getSalesBills();
    expect(listed.map((b) => b.id), [keep.id], reason: 'returned bill is not offered for return again');

    final audit = await env.db.select(env.db.salesReturnEntries).get();
    expect(audit, hasLength(2));
    expect(audit.every((e) => e.isFullBillReturn && e.billNo == back.billNo), isTrue);

    await expectLater(env.sales.returnSalesBill(back.id), throwsA(isA<ApiException>()));
  });

  test('partial returns are logged, then the last return marks the bill returned', () async {
    final sale = await env.sales.createSale(TestEnv.sale({'A': 3, 'B': 1}));

    await env.sales.returnSalesBill(sale.id, lineQuantities: {1: 2}, returnedBy: 'admin');
    expect(await reportTotal(), 200);
    var bill = await (env.db.select(env.db.cachedSalesBills)..where((t) => t.id.equals(sale.id))).getSingle();
    expect(bill.status, isNot(AppDatabase.saleStatusReturned));

    await env.sales.returnSalesBill(sale.id, lineQuantities: {1: 1, 2: 1});
    bill = await (env.db.select(env.db.cachedSalesBills)..where((t) => t.id.equals(sale.id))).getSingle();
    expect(bill.status, AppDatabase.saleStatusReturned);
    expect(await reportTotal(), 0);

    final audit = await env.db.select(env.db.salesReturnEntries).get();
    expect(audit.fold<int>(0, (s, e) => s + e.quantity), 4);
    expect(audit.where((e) => e.isFullBillReturn), hasLength(2));
    expect(await env.stockOf('A'), 50);
    expect(await env.stockOf('B'), 50);
  });

  test('bill numbers stay gap-free in the books even after returns', () async {
    final a = await env.sales.createSale(TestEnv.sale({'A': 1}));
    await env.sales.returnSalesBill(a.id);
    final b = await env.sales.createSale(TestEnv.sale({'A': 1}));
    final nos = (await env.db.select(env.db.cachedSalesBills).get()).map((x) => x.billNo).toList()..sort();
    expect(nos, [a.billNo, b.billNo]);
    expect(int.parse(b.billNo.split('-').last), int.parse(a.billNo.split('-').last) + 1);
  });
}
