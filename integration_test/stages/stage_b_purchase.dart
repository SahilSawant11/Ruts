import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';

import '../support/driver.dart';

Future<List<CachedPurchaseBill>> purchaseBills(Driver d) async =>
    (await d.t.runAsync(() => d.db.select(d.db.cachedPurchaseBills).get()))!;

Future<int> stockOf(Driver d, String id) async =>
    (await d.t.runAsync<CachedInventoryStock?>(
            () => (d.db.select(d.db.cachedInventoryStocks)..where((t) => t.materialId.equals(id))).getSingleOrNull()))
        ?.qtyOnHand ??
    0;

const _search = 'Scan barcode, type SCM code';

/// Quick-add bar: scan/type [code], Enter, type [qty], press Add Line.
Future<void> addLine(Driver d, String code, int qty) async {
  await d.t.enterText(d.hinted(_search), code);
  await d.idle(150);
  await d.enter();
  await d.typeFocused('$qty');
  await d.tapText('Add Line');
}

Future<void> setTp(Driver d, String tp) async {
  await d.tapText('SHIPPING / TP');
  await d.type('TP NO.', tp);
  await d.tapText('Done');
}

Future<String> saveBill(Driver d) async {
  await d.tapText('Save Bill');
  await d.wait(const Duration(milliseconds: 1200));
  return d.snacks();
}

Future<void> clearBill(Driver d) async {
  await d.tapText('Clear');
  await d.tapText('Clear Bill', last: true);
}

Future<void> stageB(Driver d) async {
  await d.step('b1', 'Purchase TP-1: beer + 1000 ML wine, distributor pre-filled', () async {
    await d.go('/purchase');
    await addLine(d, '111', 24);
    final supplierShown = d.shows('Magnum Traders');
    await addLine(d, 'SCMW', 6);
    await setTp(d, 'TP-1');
    final snack = await saveBill(d);
    final bills = await purchaseBills(d);
    final bill = bills.where((b) => b.tpNo == 'TP-1').toList();
    if (bill.isEmpty) return 'Not saved. Screen said: "$snack"';
    if (!supplierShown) return 'Saved, but the distributor was not pre-filled from the item.';
    final s1 = await stockOf(d, 'SCM1'), w = await stockOf(d, 'SCMW');
    return s1 == 24 && w == 6 ? null : 'Stock after purchase: SCM1=$s1, SCMW=$w (expected 24, 6).';
  });

  await d.step('b2', 'Second purchase same day, TP-2', () async {
    await d.go('/purchase');
    await addLine(d, '111', 12);
    await setTp(d, 'TP-2');
    final snack = await saveBill(d);
    final ok = (await purchaseBills(d)).any((b) => b.tpNo == 'TP-2');
    if (!ok) return 'Not saved. Screen said: "$snack"';
    final s1 = await stockOf(d, 'SCM1');
    return s1 == 36 ? null : 'SCM1 stock $s1, expected 36.';
  });

  await d.step('b3', 'Reusing TP-1 refused', () async {
    await d.go('/purchase');
    await addLine(d, '111', 5);
    await setTp(d, 'TP-1');
    final before = (await purchaseBills(d)).length;
    final snack = await saveBill(d);
    final after = (await purchaseBills(d)).length;
    await clearBill(d);
    if (after != before) return 'A second purchase with TP-1 was saved.';
    return snack.contains('TP-1') && snack.contains('already') ? null : 'Not refused with a TP message. Screen said: "$snack"';
  });

  await d.step('b4', 'Shared barcode 999 asks which SCM code', () async {
    await d.go('/purchase');
    await d.t.enterText(d.hinted(_search), '999');
    await d.idle(150);
    await d.enter();
    final asked = d.showsContaining('is on 2 items');
    final listsBoth = d.shows('SCM2') && d.shows('SCM3');
    final searchStill = d.textOf(d.hinted(_search)) == '999';
    if (!asked || !listsBoth || !searchStill) {
      return 'Expected a choice of SCM2/SCM3 and nothing picked. asked=$asked listsBoth=$listsBoth searchStill999=$searchStill';
    }
    await d.key(LogicalKeyboardKey.arrowDown);
    await d.enter();
    final picked = d.textOf(d.hinted(_search));
    if (picked != 'TUBORG STRONG B') return 'After ↓+Enter the search shows "$picked", expected TUBORG STRONG B (SCM3).';
    // Buy 2 of each for the Sales stage.
    await d.typeFocused('2');
    await d.tapText('Add Line');
    await d.t.enterText(d.hinted(_search), '999');
    await d.idle(150);
    await d.enter();
    await d.enter(); // first choice: SCM2
    await d.typeFocused('2');
    await d.tapText('Add Line');
    await setTp(d, 'TP-3');
    // SCM2/SCM3 have no default distributor: pick one, as a person would.
    await d.tapText('Select Distributor');
    await d.tapText('Magnum Traders', last: true);
    final snack = await saveBill(d);
    final s2 = await stockOf(d, 'SCM2'), s3 = await stockOf(d, 'SCM3');
    return s2 == 2 && s3 == 2 ? null : 'Stock SCM2=$s2 SCM3=$s3 (expected 2, 2). Screen said: "$snack"';
  });

  await d.step('b5', 'F2 dialog lists both items for 999', () async {
    await d.go('/purchase');
    await d.key(LogicalKeyboardKey.f2);
    if (!d.shows('Add Purchase Line')) return 'F2 did not open the Add Purchase Line dialog.';
    await d.type('SCM CODE / BARCODE', '999');
    await d.tapText('Find', last: true);
    final asked = d.showsContaining('is on 2 items');
    final rows = d.showsContaining('SCM2 · 999') && d.showsContaining('SCM3 · 999');
    await d.tapText('Cancel', last: true);
    final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? '').where((x) => x.contains('999')).toList();
    return asked && rows ? null : 'asked=$asked, both rows listed=$rows; texts with 999: $texts';
  });

  await d.step('b6', 'Quick-create beer without type refused', () async {
    await d.go('/purchase');
    await d.key(LogicalKeyboardKey.f2);
    await d.type('SCM CODE / BARCODE', 'SCMNEWBEER');
    await d.tapText('Find', last: true);
    await d.type('ITEM NAME *', 'NEW CRAFT BEER');
    await d.pick('CATEGORY', 'Beer');
    await d.type('RATE', '150');
    final typeShown = d.dropdown('TYPE *').evaluate().isNotEmpty;
    await d.tapText('Create Item & Add Line');
    final refused = d.showsContaining('Select the beer type');
    final m = await d.t.runAsync<CachedMaterial?>(
        () => (d.db.select(d.db.cachedMaterials)..where((t) => t.id.equals('SCMNEWBEER'))).getSingleOrNull());
    if (d.shows('Cancel')) await d.tapText('Cancel', last: true);
    if (m != null) return 'Beer was created without a type.';
    return typeShown && refused ? null : 'TYPE field shown=$typeShown, refusal message shown=$refused';
  });

  await d.step('b7', 'F2 opens exactly one Add Line dialog', () async {
    await d.go('/purchase');
    await d.key(LogicalKeyboardKey.f2);
    final open = find.text('Add Purchase Line').evaluate().length;
    for (var i = 0; i < open; i++) {
      await d.tapText('Cancel', last: true);
    }
    return open == 1 ? null : 'F2 opened $open dialogs.';
  });
}
