import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/features/sales/presentation/cart_controller.dart';
import 'package:pos_app/features/sales/presentation/sales_providers.dart';

import '../support/driver.dart';
import 'stage_b_purchase.dart' show stockOf;
import 'stage_e_reports.dart' show setActive;

const scanHint = 'Scan barcode, type SCM code or item name';

Future<void> scan(Driver d, String code, {int qty = 1}) async {
  if (qty != 1) {
    await d.t.enterText(d.hinted('Qty'), '$qty');
    await d.idle(100);
  }
  final before = d.c.read(cartControllerProvider).totalQty;
  // Click into the scan box (a scanner needs it focused), then scan.
  for (var attempt = 0; attempt < 2; attempt++) {
    await d.t.tap(d.hinted(scanHint), warnIfMissed: false);
    await d.idle(150);
    await d.t.enterText(d.hinted(scanHint), code);
    await d.idle(150);
    if (d.textOf(d.hinted(scanHint)) == code) break;
  }
  await d.enter();
  final after = d.c.read(cartControllerProvider).totalQty;
  lastScan = after > before
      ? 'added'
      : 'not added; error="${scanError(d)}", box="${d.textOf(d.hinted(scanHint))}", '
          'snack="${d.snacks()}", focus=${d.focused.evaluate().length}';
}

/// What the last scan did, for failure notes.
String lastScan = '';

String? scanError(Driver d) => d.c.read(cartControllerProvider).scanError;

Future<List<CachedSalesBill>> salesBills(Driver d) async =>
    (await d.t.runAsync(() => (d.db.select(d.db.cachedSalesBills)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get()))!;

/// Presses Save Bill and waits for the new bill to land. Returns the new
/// bill, or null with the screen's message in [lastMessage].
String lastMessage = '';
Future<CachedSalesBill?> saveSale(Driver d) async {
  final before = (await salesBills(d)).length;
  // A real mouse click (desktop), not a touch.
  final save = find.text('Save Bill');
  await d.t.ensureVisible(save.first);
  await d.click(save.first, settle: false);
  lastMessage = await d.catchSnack();
  await d.wait(const Duration(milliseconds: 600));
  final bills = await salesBills(d);
  return bills.length > before ? bills.last : null;
}

String? activePermit(Driver d) => d.c.read(activeLicenseHolderProvider)?.permitNo;

Future<void> openCustomerMenu(Driver d) async {
  await d.t.tap(find.byTooltip('Select Customer'));
  await d.idle(300);
}

Future<void> stageC(Driver d) async {
  await d.go('/sales');

  await d.step('c1', 'Bought beer sells without restarting', () async {
    await scan(d, '111');
    final err = scanError(d);
    if (err != null) return 'Scan refused: "$err"';
    final bill = await saveSale(d);
    return bill == null ? 'Bill not saved: "$lastMessage"' : null;
  });

  await d.step('c2', 'Permit rotates bill to bill', () async {
    final seen = <String?>[];
    for (var i = 0; i < 3; i++) {
      seen.add(activePermit(d));
      await scan(d, '111');
      final bill = await saveSale(d);
      if (bill == null) return 'Bill ${i + 1} not saved: "$lastMessage"; scan $lastScan';
      if (bill.permitNo != seen.last) return 'Bill used ${bill.permitNo} but screen showed ${seen.last}.';
    }
    final distinct = seen.toSet().length;
    return distinct == 3 ? null : 'Permits over 3 bills: $seen (expected 3 different).';
  });

  await d.step('c3', 'One Time permit bill does not skip the next holder', () async {
    final next = activePermit(d);
    await d.t.tap(find.byTooltip('Change License Holder (Auto-rotates each bill)'));
    await d.idle(300);
    await d.tapText('ONE TIME OMKAR', last: true);
    if (activePermit(d) != 'OT-1') return 'Could not pick OT-1 (active: ${activePermit(d)}).';
    await scan(d, '111');
    final bill = await saveSale(d);
    if (bill?.permitNo != 'OT-1') return 'Bill not saved on OT-1: "$lastMessage"; scan $lastScan';
    await d.wait(const Duration(milliseconds: 500));
    final after = activePermit(d);
    return after == next ? null : 'Next holder was $next before the One Time bill, now $after.';
  });

  await d.step('c4', 'New → Walk in saves a One Time permit, rotation unchanged', () async {
    final before = activePermit(d);
    await openCustomerMenu(d);
    await d.tapText('New → Walk in', last: true);
    await d.t.enterText(d.hinted('Customer name'), 'WALKIN VIJAY');
    await d.t.enterText(d.hinted('Permit / license no.'), 'WI-501');
    await d.idle(150);
    await scan(d, '111');
    final bill = await saveSale(d);
    if (bill?.permitNo != 'WI-501') return 'Bill not on WI-501: "$lastMessage"';
    final h = await d.t.runAsync<CachedLicenseHolder?>(
        () => (d.db.select(d.db.cachedLicenseHolders)..where((t) => t.permitNo.equals('WI-501'))).getSingleOrNull());
    if (h == null) return 'Walk-in holder not saved.';
    if (h.validity != 'One Time' || (h.issuedDate ?? '').isEmpty) return 'Saved as ${h.validity}, issued "${h.issuedDate}".';
    await d.wait(const Duration(milliseconds: 500));
    return activePermit(d) == before ? null : 'Rotation moved from $before to ${activePermit(d)} after a walk-in.';
  });

  await d.step('c5', 'New → Frequent Buyer (name only)', () async {
    await openCustomerMenu(d);
    await d.tapText('New → Frequent Buyer', last: true);
    await d.t.enterText(d.hinted('Customer name'), 'FB SANJAY');
    await d.idle(150);
    await scan(d, '111');
    final bill = await saveSale(d);
    if (bill == null) return 'Bill not saved: "$lastMessage"';
    final h = await d.t.runAsync<CachedLicenseHolder?>(
        () => (d.db.select(d.db.cachedLicenseHolders)..where((t) => t.name.equals('FB SANJAY'))).getSingleOrNull());
    if (h == null || h.category != 'Frequent Buyer') return 'Frequent buyer not saved.';
    if ((bill.permitNo ?? '').isEmpty) return 'Frequent-buyer bill has no permit.';
    return bill.customerId == h.id ? null : 'Bill customer is ${bill.customerId}, buyer id ${h.id}.';
  });

  await d.step('c6', 'Shared barcode 999 moves to the other SCM code', () async {
    final s2 = await stockOf(d, 'SCM2'), s3 = await stockOf(d, 'SCM3');
    for (var i = 0; i < 3; i++) {
      await scan(d, '999');
      final err = scanError(d);
      if (err != null) return 'Scan ${i + 1} refused: "$err"';
      if (lastScan != 'added') return 'Scan ${i + 1} $lastScan';
    }
    final ids = d.c.read(cartControllerProvider).items.map((i) => i.materialId).toSet();
    if (!(ids.contains('SCM2') && ids.contains('SCM3'))) return 'Cart used only $ids.';
    final bill = await saveSale(d);
    if (bill == null) return 'Bill not saved: "$lastMessage"';
    final used = (s2 - await stockOf(d, 'SCM2')) + (s3 - await stockOf(d, 'SCM3'));
    return used == 3 ? null : 'Stock dropped by $used, expected 3.';
  });

  await d.step('c7', 'Inactive item refused at the counter', () async {
    // The 1000 ML wine has stock; make it inactive, try to sell it, then
    // switch it back on for the reports.
    await setActive(d, 'SCMW', false);
    await d.go('/sales');
    await scan(d, '333');
    final err = scanError(d) ?? '';
    final inCart = d.c.read(cartControllerProvider).items.any((i) => i.materialId == 'SCMW');
    await setActive(d, 'SCMW', true);
    await d.go('/sales');
    if (inCart) return 'Inactive item was added to the cart.';
    return err.contains('inactive') ? null : 'Not added, but the message was: "$err" ($lastScan)';
  });

  await d.step('c8', '13 bottles on one bill refused', () async {
    await scan(d, '111', qty: 13);
    final err = scanError(d) ?? '';
    final inCart = d.c.read(cartControllerProvider).totalQty;
    await d.t.enterText(d.hinted('Qty'), '1');
    return err.contains('12') && inCart == 0 ? null : 'Message "$err", bottles in cart $inCart.';
  });

  await d.step('c9', 'Top-header Refresh keeps scanning working', () async {
    await d.t.tap(find.byTooltip('Refresh Screen Data'));
    await d.wait(const Duration(milliseconds: 800));
    await scan(d, '111');
    final err = scanError(d);
    final ok = d.c.read(cartControllerProvider).items.isNotEmpty;
    if (ok) await saveSale(d);
    return err == null && ok ? null : 'After Refresh the scan said: "$err"';
  });

  await d.step('c11', 'Esc closes suggestions without clearing the bill', () async {
    await d.go('/sales');
    await scan(d, '111');
    if (d.c.read(cartControllerProvider).items.isEmpty) return 'Could not add an item first ($lastScan).';
    await d.t.enterText(d.hinted(scanHint), 'KF');
    await d.idle(200);
    await d.key(LogicalKeyboardKey.escape);
    final kept = d.c.read(cartControllerProvider).items.length;
    await d.key(LogicalKeyboardKey.escape); // second Esc: clear the bill
    final cleared = d.c.read(cartControllerProvider).items.isEmpty;
    if (kept == 0) return 'Esc on the suggestion list cleared the whole bill.';
    return cleared ? null : 'A second Esc did not clear the bill.';
  });

  await d.step('c12', 'After clicking Save Bill the scan box is ready for the next scan', () async {
    await d.go('/sales');
    await scan(d, '111');
    if (lastScan != 'added') return 'Could not add an item first ($lastScan).';
    final bill = await saveSale(d); // clicks Save Bill with the mouse
    if (bill == null) return 'Bill not saved: "$lastMessage"';
    final focused = d.focused.evaluate();
    final onScanBox = focused.isNotEmpty &&
        find.descendant(of: d.hinted(scanHint), matching: d.focused).evaluate().isNotEmpty;
    return onScanBox
        ? null
        : 'After saving, keyboard focus is ${focused.isEmpty ? 'nowhere' : 'on another field'} — a scanner\'s next scan would be lost.';
  });
}
