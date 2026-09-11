import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/masters/data/models/category_dto.dart';
import 'package:pos_app/features/masters/data/models/manufacturer_dto.dart';
import 'package:pos_app/features/masters/data/models/packaging_dto.dart';
import 'package:pos_app/features/masters/presentation/material_browser_controller.dart';
import 'package:pos_app/features/masters/presentation/widgets/material_form_card.dart';
import 'package:pos_app/features/sales/data/models/material_dto.dart';
import 'package:pos_app/shared/widgets/inputs/app_dropdown.dart';
import 'package:pos_app/shared/widgets/inputs/app_text_field.dart';

void main() {
  testWidgets('MaterialFormCard displays PACKING as AppDropdown when editable', (tester) async {
    const testMaterial = MaterialDto(
      id: 'SKU-TEST',
      barcode: '1234567890123',
      name: 'Test Whisky',
      manufacturer: 'Royal Stag',
      category: 'Whisky',
      packing: '750 ML',
      saleRate: 1000,
      taxPercent: 18,
      stockQty: 10,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          materialsListProvider.overrideWith((ref) async => [testMaterial]),
          materialBrowserProvider.overrideWith((ref) {
            final controller = MaterialBrowserController();
            controller.syncList([testMaterial]);
            controller.selectById(testMaterial.id);
            return controller;
          }),
          manufacturersListProvider.overrideWith((ref) async => [
                const ManufacturerDto(name: 'Royal Stag'),
              ]),
          categoriesListProvider.overrideWith((ref) async => [
                const CategoryDto(name: 'Whisky'),
              ]),
          packingsListProvider.overrideWith((ref) async => [
                const PackagingDto(name: '750 ML', description: 'Bottle'),
                const PackagingDto(name: '375 ML', description: 'Half'),
              ]),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: MaterialFormCard()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial material is loaded into the controller
    expect(
      find.byWidgetPredicate((w) => w is TextField && w.controller?.text == 'Test Whisky'),
      findsOneWidget,
    );

    // Locked state: should show AppTextField with hint '750 ML'
    expect(
      find.byWidgetPredicate((w) => w is AppTextField && w.label == 'PACKING' && w.hint == '750 ML'),
      findsOneWidget,
    );

    // Tap "Modify" button to enter editing mode
    final modifyButton = find.text('Modify');
    expect(modifyButton, findsOneWidget);
    await tester.tap(modifyButton);
    await tester.pumpAndSettle();

    // Now in editable mode: AppDropdown<String> for PACKING should be present
    final packingDropdown = find.byWidgetPredicate(
      (widget) => widget is AppDropdown<String> && widget.label == 'PACKING',
    );
    expect(packingDropdown, findsOneWidget);
  });
}
