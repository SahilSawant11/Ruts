// Bulk delete from the masters screens must never orphan a bill, stock or
// a report row: records still in use are skipped and reported.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/features/masters/data/local_masters_repository.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/masters/presentation/widgets/categories_table.dart';
import 'package:pos_app/features/purchase/data/models/create_purchase_request.dart';

import 'support/test_env.dart';

void main() {
  late TestEnv env;
  setUp(() async => env = await TestEnv.create(fileBacked: false));
  tearDown(() async => env.dispose());

  Future<List<String>> materialIds() async => (await env.masters.getMaterials()).map((m) => m.id).toList();

  test('materials: unused ones go; ones on bills or with stock are kept', () async {
    await env.addMaterial('SOLD', stock: 10);
    await env.addMaterial('STOCKED', stock: 5);
    await env.addMaterial('UNUSED', stock: 0);
    await env.sales.createSale(TestEnv.sale({'SOLD': 10})); // stock back to 0, but on a bill

    final r = await env.masters.deleteMasters(MasterKind.material, ['SOLD', 'STOCKED', 'UNUSED']);

    expect(r.deleted, ['UNUSED']);
    expect(r.kept, {'SOLD': 'on bills', 'STOCKED': 'has stock'});
    expect(await materialIds(), unorderedEquals(['SOLD', 'STOCKED']));
    final stockRows = await (env.db.select(env.db.cachedInventoryStocks)..where((t) => t.materialId.equals('UNUSED'))).get();
    expect(stockRows, isEmpty);
  });

  test('suppliers on a purchase bill are kept', () async {
    await env.addMaterial('A', stock: 0);
    for (final id in ['SUP-1', 'SUP-2']) {
      await env.db.into(env.db.cachedSuppliers).insert(CachedSuppliersCompanion.insert(id: id, name: 'Supplier $id'));
    }
    await env.purchases.createPurchase(const CreatePurchaseRequest(
      supplierId: 'SUP-1',
      billNo: 'INV-1',
      payMode: 'Credit',
      discount: 0,
      vat: 0,
      stamp: 0,
      tcs: 0,
      loadingFreight: 0,
      netAmount: 50,
      totalAmount: 50,
      lineItems: [
        CreatePurchaseLineItemRequest(
          materialId: 'A',
          batchNo: 'B1',
          qty: 1,
          rate: 50,
          disPercent: 0,
          disAmount: 0,
          taxPercent: 0,
          taxAmount: 0,
          amount: 50,
        ),
      ],
    ));

    final r = await env.masters.deleteMasters(MasterKind.supplier, ['SUP-1', 'SUP-2']);
    expect(r.deleted, ['SUP-2']);
    expect(r.kept.keys, ['SUP-1']);
  });

  test('category, manufacturer and packaging in use by a product are kept', () async {
    await env.addMaterial('A', stock: 0); // Whisky, 750 ML
    await (env.db.update(env.db.cachedMaterials)..where((t) => t.id.equals('A')))
        .write(const CachedMaterialsCompanion(manufacturer: Value('Diageo')));
    await env.db.into(env.db.cachedCategories).insert(CachedCategoriesCompanion.insert(name: 'Whisky'));
    await env.db.into(env.db.cachedCategories).insert(CachedCategoriesCompanion.insert(name: 'Rum'));
    await env.db.into(env.db.cachedManufacturers).insert(CachedManufacturersCompanion.insert(name: 'Diageo'));
    await env.db.into(env.db.cachedManufacturers).insert(CachedManufacturersCompanion.insert(name: 'Old Co'));
    await env.db.into(env.db.cachedPackings).insert(CachedPackingsCompanion.insert(name: '750 ML'));
    await env.db.into(env.db.cachedPackings).insert(CachedPackingsCompanion.insert(name: '90 ML'));

    final c = await env.masters.deleteMasters(MasterKind.category, ['Whisky', 'Rum']);
    final m = await env.masters.deleteMasters(MasterKind.manufacturer, ['Diageo', 'Old Co']);
    final p = await env.masters.deleteMasters(MasterKind.packaging, ['750 ML', '90 ML']);

    expect([c.deleted, c.kept.keys.toList()], [['Rum'], ['Whisky']]);
    expect([m.deleted, m.kept.keys.toList()], [['Old Co'], ['Diageo']]);
    expect([p.deleted, p.kept.keys.toList()], [['90 ML'], ['750 ML']]);
  });

  test('license holders always delete', () async {
    for (final id in ['P1', 'P2']) {
      await env.db.into(env.db.cachedLicenseHolders).insert(
            CachedLicenseHoldersCompanion.insert(id: id, permitNo: id, name: 'Holder $id'),
          );
    }
    final r = await env.masters.deleteMasters(MasterKind.licenseHolder, ['P1', 'P2']);
    expect(r.deleted, unorderedEquals(['P1', 'P2']));
    expect(await env.masters.getLicenseHolders(), isEmpty);
  });

  testWidgets('select all, bulk delete, in-use rows stay selected', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await env.addMaterial('A', stock: 0); // category Whisky
    await tester.runAsync(() async {
      for (final c in ['Whisky', 'Rum', 'Gin']) {
        await env.db.into(env.db.cachedCategories).insert(CachedCategoriesCompanion.insert(name: c));
      }
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(env.db)],
      child: const MaterialApp(home: Scaffold(body: SizedBox(height: 800, child: CategoriesTable(isSplitView: true)))),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();

    expect(find.byType(Checkbox), findsNWidgets(4)); // header + 3 rows
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(find.text('3 selected'), findsOneWidget);

    await tester.tap(find.text('Delete 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();

    final left = await tester.runAsync(() => env.masters.getCategories());
    expect(left!.map((c) => c.name), ['Whisky']);
    expect(find.text('1 selected'), findsOneWidget);
  });
}
