import 'package:drift/drift.dart' show Value;
import 'package:excel_community/excel_community.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/features/masters/data/models/save_license_holder_request.dart';
import 'package:pos_app/features/reports/data/license_holder_report.dart';
import 'package:pos_app/features/reports/data/reports_providers.dart';
import 'package:pos_app/features/reports/presentation/widgets/license_holder_report_table.dart';
import 'package:pos_app/features/sales/data/models/create_sale_request.dart';

import 'support/test_env.dart';

void main() {
  test('license holder report: qty per license, day / month / custom ranges, returns excluded', () async {
    final env = await TestEnv.create(fileBacked: false);
    addTearDown(env.dispose);
    await env.addMaterial('W1', stock: 500);
    await env.masters.createLicenseHolder(const SaveLicenseHolderRequest(permitNo: 'P-100', name: 'B J RAMA', validity: 'Lifetime'));
    await env.masters.createLicenseHolder(const SaveLicenseHolderRequest(permitNo: 'P-200', name: 'S K PATIL', validity: 'One Time'));

    Future<String> sell(String? permit, int qty, DateTime when, {String? billName}) async {
      final base = TestEnv.sale({'W1': qty});
      final r = await env.sales.createSale(CreateSaleRequest(
        billNo: base.billNo, payMode: base.payMode, taxableValue: base.taxableValue, totalDiscount: 0,
        totalTax: 0, totalAmount: base.totalAmount, balanceDue: base.balanceDue, lineItems: base.lineItems,
        permitNo: permit, permitHolderName: billName,
      ));
      await (env.db.update(env.db.cachedSalesBills)..where((t) => t.id.equals(r.id)))
          .write(CachedSalesBillsCompanion(billDate: Value(when)));
      return r.id;
    }

    final nov18 = DateTime(2026, 11, 18, 11);
    await sell('P-100', 2, nov18);
    await sell('P-100', 3, nov18.add(const Duration(hours: 2)));
    await sell('P-200', 6, nov18, billName: 'old name on bill');
    final returned = await sell('P-200', 10, nov18);
    await env.sales.returnSalesBill(returned);
    await sell(null, 4, nov18); // no permit → not in the report
    await sell('P-100', 1, DateTime(2026, 11, 2, 10));
    await sell('P-300', 7, DateTime(2026, 10, 30, 10), billName: 'NOT IN MASTER');

    final day = await LicenseHolderReport.build(env.db, DateTime(2026, 11, 18), DateTime(2026, 11, 18, 23, 59, 59, 999));
    expect(day.rows.map((r) => r.permitNo), ['P-200', 'P-100']); // highest qty first
    expect(day.rows.map((r) => r.qtyBottles), [6, 5]);
    expect(day.rows.map((r) => r.bills), [1, 2]);
    expect(day.rows.first.name, 'S K PATIL'); // name from the master
    expect(day.rows.first.validity, 'One Time');
    expect(day.rows.last.amount, 500);
    expect(day.totalQtyBottles, 11);

    final month = await LicenseHolderReport.build(env.db, DateTime(2026, 11, 1), DateTime(2026, 11, 30, 23, 59, 59, 999));
    expect({for (final r in month.rows) r.permitNo: r.qtyBottles}, {'P-100': 6, 'P-200': 6});

    final custom = await LicenseHolderReport.build(env.db, DateTime(2026, 10, 1), DateTime(2026, 11, 5, 23, 59, 59));
    expect({for (final r in custom.rows) r.permitNo: (r.name, r.qtyBottles)},
        {'P-300': ('NOT IN MASTER', 7), 'P-100': ('B J RAMA', 1)});

    final sheet = Excel.decodeBytes(LicenseHolderReportExporter.encode(day)).tables.values.first;
    expect(sheet.rows.first.map((c) => c?.value.toString()), LicenseHolderReportExporter.headers);
    expect(sheet.rows[1][1]?.value.toString(), 'P-200');
    expect(sheet.rows.last[2]?.value.toString(), 'Total');
    expect(sheet.rows.last[6]?.value.toString(), '11');
  });

  testWidgets('license holder table shows rows and totals', (tester) async {
    final report = LicenseHolderReport(from: DateTime(2026, 11, 18), to: DateTime(2026, 11, 18), rows: const [
      LicenseHolderReportRow(permitNo: 'P-200', name: 'S K PATIL', validity: 'One Time', bills: 1, qtyCase: 0, qtyBottles: 6, amount: 600),
      LicenseHolderReportRow(permitNo: 'P-100', name: 'B J RAMA', validity: 'Lifetime', bills: 2, qtyCase: 1, qtyBottles: 5, amount: 500),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [licenseHolderReportProvider.overrideWith((ref) async => report)],
      child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: LicenseHolderReportTable()))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('LICENSE NO'), findsOneWidget);
    expect(find.text('P-200'), findsOneWidget);
    expect(find.text('B J RAMA'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('₹1100.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
