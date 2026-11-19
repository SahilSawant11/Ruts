import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/core/theme/app_icons.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';

import '../support/driver.dart';
import 'stage_b_purchase.dart' show stockOf;
import 'stage_c_sales.dart';

String returnTrace = '';

Finder _icon(AppIconData icon) => find.byWidgetPredicate((w) => w is AppIcon && w.icon == icon);

/// On a Returns screen: search [billNo], open it, tick line [line] (or all),
/// set its return qty to [qty] with the − button, process and confirm.
Future<String> returnBill(Driver d,
    {required String searchHint, required String billNo, String? title, int? line, int? qty, int? lineQty}) async {
  await d.search(searchHint, billNo);
  await d.tapText(title ?? billNo, last: true);
  await d.wait(const Duration(milliseconds: 900)); // bill details load
  final boxes = find.byType(Checkbox);
  String states() => boxes.evaluate().map((e) {
        final c = e.widget as Checkbox;
        final box = e.renderObject as RenderBox;
        return '${c.value}@${box.localToGlobal(Offset.zero).dy.round()}';
      }).join(',');
  final before = states();
  // Opening a bill already ticks every line; tick only if needed.
  final target = line == null ? boxes.first : boxes.at(line + 1);
  if ((target.evaluate().first.widget as Checkbox).value != true) {
    await d.t.tap(target);
    await d.idle();
  }
  returnTrace = 'checkboxes $before -> ${states()}';
  if (qty != null && lineQty != null) {
    for (var i = qty; i < lineQty; i++) {
      await d.t.tap(_icon(AppIcons.remove).first);
      await d.idle(120);
    }
  }
  // "Process Full Return" or "Process Return (n bottles)".
  final process = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').startsWith('Process '));
  await d.t.ensureVisible(process.first);
  await d.t.tap(process.first);
  await d.idle();
  await d.tapText('Confirm Return', last: true);
  await d.wait(const Duration(milliseconds: 1200));
  return d.snacks();
}

Future<void> stageD(Driver d) async {
  await d.step('d1', 'Partial sales return, returned bottle sells again', () async {
    await d.go('/sales');
    await scan(d, '111', qty: 3);
    final bill = await saveSale(d);
    if (bill == null) return 'Could not make the 3-bottle bill: "$lastMessage"';
    final stock = await stockOf(d, 'SCM1');
    await d.go('/sales-return');
    final msg = await returnBill(d, searchHint: 'Search Bill #', billNo: bill.billNo, line: 0, qty: 1, lineQty: 3);
    final after = await stockOf(d, 'SCM1');
    if (after != stock + 1) return 'Stock $stock → $after after returning 1 (screen: "$msg"). $returnTrace';
    await d.go('/sales');
    await scan(d, '111');
    final err = scanError(d);
    final sold = await saveSale(d);
    return err == null && sold != null ? null : 'Returned bottle did not sell: "${err ?? lastMessage}"';
  });

  await d.step('d2', 'Full return brings One Time permit back to rotation', () async {
    final bills = await salesBills(d);
    final ot = bills.where((b) => b.permitNo == 'OT-1').toList();
    if (ot.isEmpty) return 'No OT-1 bill to return (c3 must pass first).';
    await d.go('/sales-return');
    final msg = await returnBill(d, searchHint: 'Search Bill #', billNo: ot.first.billNo);
    final status = (await d.t.runAsync<CachedSalesBill?>(
            () => (d.db.select(d.db.cachedSalesBills)..where((t) => t.id.equals(ot.first.id))).getSingleOrNull()))
        ?.status;
    if (status != 'returned') return 'Bill not fully returned (status $status, screen "$msg").';
    final rotation = await d.t.runAsync(() => d.c.read(mastersRepositoryProvider).getRotationLicenseHolders());
    return rotation!.any((h) => h.permitNo == 'OT-1') ? null : 'OT-1 is not back in the rotation.';
  });

  await d.step('d3', 'Partial purchase return lowers stock', () async {
    final before = await stockOf(d, 'SCM1');
    await d.go('/purchase-return');
    // Find the purchase by its TP number, as on the paperwork.
    final msg = await returnBill(d, searchHint: 'Search Bill #, Challan', billNo: 'TP-2', title: 'TP TP-2', line: 0, qty: 2, lineQty: 12);
    final after = await stockOf(d, 'SCM1');
    return after == before - 2 ? null : 'SCM1 stock $before → $after, expected −2 (screen "$msg").';
  });
}
