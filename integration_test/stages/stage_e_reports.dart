import 'dart:io';

import 'package:excel_community/excel_community.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/reports/data/brandwise_report_provider.dart';
import 'package:pos_app/features/reports/data/counter_brandwise_report_provider.dart';
import 'package:pos_app/features/reports/data/license_holder_report.dart';
import 'package:pos_app/features/reports/data/reports_providers.dart';

import '../support/driver.dart';
import 'stage_a_masters.dart' show createMaterial;

/// "… saved to /path/file.xlsx" → the file (deleted by the caller).
File? savedFile(String snack) {
  final m = RegExp(r'saved to (.+?\.(?:xlsx|xls|xml))').firstMatch(snack);
  return m == null ? null : File(m.group(1)!);
}

/// Clicks Export Excel and returns the "saved to …" message the moment it
/// shows (it disappears after 2 s; waiting for the screen to settle can
/// miss it).
Future<String> exportExcel(Driver d) async {
  final button = find.text('Export Excel').first;
  await d.t.ensureVisible(button);
  await d.t.tap(button);
  return d.catchSnack(timeout: const Duration(seconds: 6));
}

Future<String> setActive(Driver d, String code, bool active) async {
  Future<bool?> isActive() async => (await d.t.runAsync(
          () => (d.db.select(d.db.cachedMaterials)..where((t) => t.id.equals(code))).getSingleOrNull()))
      ?.isActive;
  if (await isActive() == active) return '';
  await d.go('/material');
  await d.search('Search name, SCM code', code);
  await d.tapText(code, last: true);
  await d.tapText('Edit');
  // The form's toggle is the last Active/Inactive label (list rows show pills too).
  await d.tapText(active ? 'Inactive' : 'Active', last: true);
  await d.tapText('Save');
  await d.wait(const Duration(milliseconds: 800));
  await d.search('Search name, SCM code', '');
  final msg = d.snacks();
  if (await isActive() != active) throw StateError('could not set $code active=$active ($msg)');
  return msg;
}

Future<void> generateBrandwise(Driver d) async {
  await d.go('/brandwise-report');
  await d.tapText('Brandwise');
  await d.tapText('Generate');
  await d.wait(const Duration(milliseconds: 800));
}

Future<void> stageE(Driver d) async {
  await d.step('e1', 'Brandwise: one row per TP', () async {
    await generateBrandwise(d);
    final r = await d.t.runAsync(() => d.c.read(brandwiseReportProvider.future));
    final strong = r!.categories.firstWhere((c) => c.name == 'STRONG BEER').items;
    final kf = strong.where((i) => i.brandName == 'KF STRONG 650').toList();
    final tps = kf.map((i) => i.tpNo).toList();
    if (tps.length < 2 || tps[0] != 'TP-1' || tps[1] != 'TP-2') return 'KF STRONG 650 rows have TPs $tps.';
    if (!kf[1].isTpContinuation) return 'TP-2 row is not a continuation row.';
    return d.shows('TP-1') && d.shows('TP-2') ? null : 'TP numbers not visible on screen.';
  });

  await d.step('e2', 'Brandwise: 1000ml column', () async {
    final r = await d.t.runAsync(() => d.c.read(brandwiseReportProvider.future));
    if (!r!.extraSizes.contains('1000ml')) return 'Extra sizes: ${r.extraSizes}.';
    return d.shows('1000ml') ? null : '1000ml column not on screen.';
  });

  await d.step('e3', 'Brandwise totals match the bills', () async {
    final r = (await d.t.runAsync(() => d.c.read(brandwiseReportProvider.future)))!;
    final saleTotal = r.categories.fold<int>(0, (s, c) => s + c.subtotal.sale.total);
    final purchaseTotal = r.categories.fold<int>(0, (s, c) => s + c.subtotal.purchase.total);
    final soldRows = await d.t.runAsync(() => d.db.customSelect(
          "SELECT COALESCE(SUM(l.quantity),0) AS q FROM cached_sale_line_items l JOIN cached_sales_bills b "
          "ON b.id = l.sales_bill_id WHERE b.status != 'returned'",
        ).getSingle());
    final boughtRows = await d.t.runAsync(() => d.db.customSelect(
          'SELECT COALESCE(SUM(l.qty),0) AS q FROM cached_purchase_line_items l JOIN cached_purchase_bills p '
          'ON p.id = l.purchase_bill_id WHERE p.returned_at IS NULL',
        ).getSingle());
    final sold = soldRows!.read<int>('q'), bought = boughtRows!.read<int>('q');
    return saleTotal == sold && purchaseTotal == bought
        ? null
        : 'Register sale $saleTotal vs bills $sold; register purchase $purchaseTotal vs bills $bought.';
  });

  await d.step('e4', 'Counter Brandwise: case variants are one line', () async {
    await d.tapText('Counter Brandwise');
    await d.tapText('Generate');
    await d.wait(const Duration(milliseconds: 800));
    final r = (await d.t.runAsync(() => d.c.read(counterBrandwiseReportProvider.future)))!;
    final lines = r.categories
        .expand((c) => c.items)
        .where((i) => !i.isTpContinuation && i.manufacturerName.toLowerCase() == 'kingfisher strong')
        .length;
    await d.tapText('Brandwise');
    return lines == 1 ? null : 'Kingfisher Strong appears on $lines lines.';
  });

  await d.step('e5', 'Sold item made inactive stays in today\'s register', () async {
    await setActive(d, 'SCM3', false);
    await generateBrandwise(d);
    final r = (await d.t.runAsync(() => d.c.read(brandwiseReportProvider.future)))!;
    final names = r.categories.expand((c) => c.items).map((i) => i.brandName);
    return names.contains('TUBORG STRONG B') ? null : 'TUBORG STRONG B (sold, now inactive) is missing.';
  });

  await d.step('e6', 'Show all: idle active shows, idle inactive hidden', () async {
    await createMaterial(d, scm: 'SCMIDLE', barcode: '888', name: 'IDLE INACTIVE BEER', category: 'Beer', type: 'Mild', packing: '650 ML');
    await setActive(d, 'SCMIDLE', false);
    await generateBrandwise(d);
    await d.tapText('Show all materials');
    await d.wait(const Duration(milliseconds: 800));
    final r = (await d.t.runAsync(() => d.c.read(brandwiseReportProvider.future)))!;
    final names = r.categories.expand((c) => c.items).map((i) => i.brandName).toSet();
    await d.tapText('Show all materials');
    // The new item must still be itself after being switched off.
    final idle = await d.t.runAsync(
        () => (d.db.select(d.db.cachedMaterials)..where((t) => t.id.equals('SCMIDLE'))).getSingleOrNull());
    if (idle?.name != 'IDLE INACTIVE BEER' || idle?.barcode != '888') {
      return 'SCMIDLE was overwritten: now "${idle?.name}" / ${idle?.barcode}.';
    }
    if (!names.contains('KF STRONG 500 CAN')) return 'Idle active KF STRONG 500 CAN not shown with Show all.';
    return names.contains('IDLE INACTIVE BEER') ? 'Idle inactive IDLE INACTIVE BEER is shown.' : null;
  });

  await d.step('e7', 'License Holders report: day, month, custom', () async {
    await d.go('/reports');
    await d.tapText('License Holders');
    await d.tapText('Day-wise');
    await d.wait(const Duration(milliseconds: 600));
    final day = (await d.t.runAsync(() => d.c.read(licenseHolderReportProvider.future)))!;
    final expected = await d.t.runAsync(() => d.db.customSelect(
          "SELECT b.permit_no AS p, SUM(l.quantity) AS q FROM cached_sales_bills b JOIN cached_sale_line_items l "
          "ON l.sales_bill_id = b.id WHERE b.status != 'returned' AND COALESCE(b.permit_no,'') != '' GROUP BY b.permit_no",
        ).get());
    final want = {for (final r in expected!) r.read<String>('p'): r.read<int>('q')};
    final got = {for (final r in day.rows) r.permitNo: r.qtyBottles};
    if (want.toString() != (Map.fromEntries(want.keys.map((k) => MapEntry(k, got[k])))).toString() ||
        got.length != want.length) {
      return 'Report $got vs bills $want.';
    }
    if (!d.shows(day.rows.first.permitNo)) return 'Top license ${day.rows.first.permitNo} not on screen.';
    await d.tapText('Monthly');
    await d.wait(const Duration(milliseconds: 600));
    final month = (await d.t.runAsync(() => d.c.read(licenseHolderReportProvider.future)))!;
    await d.tapText('Custom');
    await d.idle();
    return month.totalQtyBottles >= day.totalQtyBottles ? null : 'Month total below day total.';
  });

  await d.step('e8', 'License Holders Excel export', () async {
    await d.tapText('Day-wise');
    final snack = await exportExcel(d);
    final f = savedFile(snack);
    if (f == null || !f.existsSync()) return 'No file reported: "$snack"';
    final sheet = Excel.decodeBytes(f.readAsBytesSync()).tables.values.first;
    f.deleteSync();
    final header = sheet.rows.first.map((c) => c?.value.toString()).toList();
    if (header.toString() != LicenseHolderReportExporter.headers.toString()) return 'Header row $header.';
    return sheet.rows.last[2]?.value.toString() == 'Total' ? null : 'No Total row.';
  });

  await d.step('e9', 'SCM Daily Sale export: one row per SCM code', () async {
    await d.tapText('SCM Daily Sale', last: true);
    final snack = await exportExcel(d);
    final f = savedFile(snack);
    if (f == null || !f.existsSync()) return 'No file reported: "$snack"';
    final sheet = Excel.decodeBytes(f.readAsBytesSync()).tables.values.first;
    f.deleteSync();
    final scm1 = sheet.rows.skip(1).where((r) => r[1]?.value.toString() == 'SCM1').toList();
    if (scm1.length != 1) return 'SCM1 has ${scm1.length} rows.';
    final sold = await d.t.runAsync(() => d.db.customSelect(
          "SELECT COALESCE(SUM(l.quantity),0) AS q FROM cached_sale_line_items l JOIN cached_sales_bills b "
          "ON b.id = l.sales_bill_id JOIN cached_materials m ON m.id = l.material_id "
          "WHERE b.status != 'returned' AND m.scm_code = 'SCM1'",
        ).getSingle());
    final inFile = int.tryParse(scm1.single[5]?.value.toString() ?? '') ?? 0;
    return inFile == sold!.read<int>('q') ? null : 'SCM1 loose qty in file $inFile vs bills ${sold.read<int>('q')}.';
  });

  await d.step('e10', 'Brandwise Excel matches the screen', () async {
    await generateBrandwise(d);
    final snack = await exportExcel(d);
    final f = savedFile(snack);
    if (f == null || !f.existsSync()) return 'No file reported: "$snack"';
    final xml = f.readAsStringSync();
    f.deleteSync();
    final missing = ['TP-1', 'TP-2', '1000ml', 'KF STRONG 650'].where((s) => !xml.contains(s)).toList();
    return missing.isEmpty ? null : 'Excel lacks: $missing.';
  });

  // Keep providers referenced for analyzer when steps change.
  d.c.read(reportDateRangeProvider);
}
