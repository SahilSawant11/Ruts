import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/purchase/presentation/widgets/add_material_line_dialog.dart';
import 'package:pos_app/features/sales/data/models/material_dto.dart';
import 'package:pos_app/shared/widgets/inputs/app_text_field.dart';

const _a = MaterialDto(id: 'SCM2', scmCode: 'SCM2', barcode: '999', name: 'A', manufacturer: 'UB', category: 'Beer', packing: '650 ML', saleRate: 100, taxPercent: 0, stockQty: 0);
const _b = MaterialDto(id: 'SCM3', scmCode: 'SCM3', barcode: '999', name: 'B', manufacturer: 'UB', category: 'Beer', packing: '650 ML', saleRate: 100, taxPercent: 0, stockQty: 0);

void main() {
  testWidgets('Add Line dialog: Find on a shared barcode asks which SCM code', (t) async {
    t.view.physicalSize = const Size(1400, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [
        materialsListProvider.overrideWith((ref) async => const [_a, _b]),
        manufacturersListProvider.overrideWith((ref) async => const []),
        categoriesListProvider.overrideWith((ref) async => const []),
        packingsListProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(home: Scaffold(body: Builder(builder: (c) => TextButton(onPressed: () => showAddMaterialLineDialog(c), child: const Text('open'))))),
    ));
    await t.pumpAndSettle();
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    final f = find.descendant(of: find.byWidgetPredicate((w) => w is AppTextField && w.label == 'SCM CODE / BARCODE'), matching: find.byType(TextField));
    await t.enterText(f, '999');
    await t.pump();
    await t.tap(find.text('Find').last);
    await t.pumpAndSettle();
    expect(find.textContaining('is on 2 items'), findsOneWidget);
  });
}
