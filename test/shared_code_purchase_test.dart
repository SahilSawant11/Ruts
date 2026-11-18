import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/material_lookup_cache.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/masters/data/models/packaging_dto.dart';
import 'package:pos_app/features/purchase/presentation/widgets/purchase_quick_add_bar.dart';
import 'package:pos_app/features/sales/data/models/material_dto.dart';

// Your example: barcode 85458000 is on SCM3756 and SCM4756.
const _a = MaterialDto(
    id: 'SCM3756', scmCode: 'SCM3756', barcode: '85458000', name: 'Kingfisher Strong 100Q', manufacturer: 'UB',
    category: 'Beer', packing: '650 ML', saleRate: 100, taxPercent: 0, stockQty: 50);
const _b = MaterialDto(
    id: 'SCM4756', scmCode: 'SCM4756', barcode: '85458000', name: 'Kingfisher Strong 100', manufacturer: 'UB',
    category: 'Beer', packing: '650 ML', saleRate: 100, taxPercent: 0, stockQty: 10);
const _c = MaterialDto(
    id: 'SCM9999', scmCode: 'SCM9999', barcode: '11112222', name: 'Bacardi Black', manufacturer: 'Bacardi',
    category: 'Rum', packing: '180 ML', saleRate: 100, taxPercent: 0, stockQty: 5);

void main() {
  test('materialsForCode: shared barcode → all; SCM code or id → exactly one', () {
    const all = [_a, _b, _c];
    expect(materialsForCode(all, '85458000').map((m) => m.id), ['SCM3756', 'SCM4756']);
    expect(materialsForCode(all, 'SCM4756').map((m) => m.id), ['SCM4756']);
    expect(materialsForCode(all, '11112222').map((m) => m.id), ['SCM9999']);
    expect(materialsForCode(all, 'nope'), isEmpty);
    // Sales still auto-picks (active, most stock) — unchanged.
    expect(MaterialLookupCache.fromMaterials(all).findByBarcodeOrId('85458000')?.id, 'SCM3756');
  });

  Future<void> pumpBar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        materialsListProvider.overrideWith((ref) async => const [_a, _b, _c]),
        packingsListProvider.overrideWith((ref) async => const [PackagingDto(name: '650 ML', description: '')]),
        materialLookupCacheProvider.overrideWith((ref) => MaterialLookupCache.fromMaterials(const [_a, _b, _c])),
      ],
      child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: PurchaseQuickAddBar()))),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('purchase: scanning a shared barcode asks which SCM code, never guesses', (tester) async {
    await pumpBar(tester);
    await tester.enterText(find.byType(TextField).first, '85458000');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter); // the scanner's Enter
    await tester.pumpAndSettle();

    expect(find.textContaining('is on 2 items'), findsOneWidget);
    expect(find.text('SCM3756'), findsOneWidget);
    expect(find.text('SCM4756'), findsOneWidget);
    // Nothing chosen yet: the search box still holds the barcode.
    expect(find.widgetWithText(TextField, '85458000'), findsOneWidget);

    // Person picks the second one (arrow down + Enter).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Kingfisher Strong 100'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('purchase: a barcode on one item is picked straight away', (tester) async {
    await pumpBar(tester);
    await tester.enterText(find.byType(TextField).first, '11112222');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.textContaining('is on'), findsNothing);
    expect(find.widgetWithText(TextField, 'Bacardi Black'), findsOneWidget);
  });
}
