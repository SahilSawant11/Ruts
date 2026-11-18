// Client meeting 14 Nov 2026: STRONG BEER register section, TP No in the
// brandwise reports, VAT/TCS as percent, and blank master import templates.
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' show XFile;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/features/masters/data/master_import_service.dart';
import 'package:pos_app/features/masters/data/master_template_service.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/purchase/data/models/create_purchase_request.dart';
import 'package:pos_app/features/purchase/presentation/purchase_form_controller.dart';
import 'package:pos_app/features/reports/data/brandwise_report_provider.dart';
import 'package:pos_app/features/reports/data/brandwise_sections.dart';
import 'package:pos_app/features/reports/data/counter_brandwise_report_provider.dart';

import 'support/test_env.dart';

void main() {
  test('categories map to the four register sections', () {
    expect(brandwiseSection('Fermented Beer'), 'FERMENTED BEER');
    expect(brandwiseSection('Strong Beer'), 'STRONG BEER');
    expect(brandwiseSection('STRONG'), 'STRONG BEER');
    expect(brandwiseSection('Mild Beer'), 'MILD BEER');
    expect(brandwiseSection('Beer'), 'MILD BEER');
    expect(brandwiseSection('Whisky'), 'WINE');
    expect(brandwiseSection('Soft Drink'), isNull);
    expect(joinTpNos(['TP-9', null, ' ', 'TP-9', 'TP-10']), 'TP-9, TP-10');
  });

  test('brandwise reports show STRONG BEER section and purchase TP numbers', () async {
    final env = await TestEnv.create(fileBacked: false);
    addTearDown(env.dispose);
    Future<void> beer(String id, String name, String category) async {
      await env.addMaterial(id, stock: 0);
      await (env.db.update(env.db.cachedMaterials)..where((t) => t.id.equals(id))).write(
          CachedMaterialsCompanion(name: Value(name), category: Value(category), packing: const Value('650 ML')));
    }

    await beer('KS', 'KINGFISHER STRONG', 'Strong Beer');
    await beer('KM', 'KINGFISHER PREMIUM', 'Mild Beer');

    Future<void> purchase(String tp, Map<String, int> qty) => env.purchases.createPurchase(CreatePurchaseRequest(
          supplierId: 'SUP-1', billNo: 'INV-$tp', payMode: 'Credit', tpNo: tp, discount: 0, vat: 0, stamp: 0,
          tcs: 0, loadingFreight: 0, netAmount: 0, totalAmount: 0,
          lineItems: [
            for (final e in qty.entries)
              CreatePurchaseLineItemRequest(
                  materialId: e.key, batchNo: 'B', qty: e.value, rate: 100, disPercent: 0, disAmount: 0,
                  taxPercent: 0, taxAmount: 0, amount: e.value * 100),
          ],
        ));
    await purchase('TP-101', {'KS': 24, 'KM': 12});
    await purchase('TP-102', {'KS': 12});

    final container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(env.db)]);
    addTearDown(container.dispose);

    final report = await container.read(brandwiseReportProvider.future);
    expect(report.categories.map((c) => c.name), ['FERMENTED BEER', 'STRONG BEER', 'MILD BEER', 'WINE']);
    final strong = report.categories.firstWhere((c) => c.name == 'STRONG BEER').items.single;
    expect(strong.brandName, 'KINGFISHER STRONG');
    expect(strong.purchase.beer650, 36);
    expect(strong.tpNo, 'TP-101, TP-102');
    final mild = report.categories.firstWhere((c) => c.name == 'MILD BEER').items.single;
    expect(mild.tpNo, 'TP-101');

    final counter = await container.read(counterBrandwiseReportProvider.future);
    final counterStrong = counter.categories.firstWhere((c) => c.name == 'STRONG BEER').items.single;
    expect(counterStrong.tpNo, 'TP-101, TP-102');
  });

  test('VAT % on goods, TCS % on goods + VAT, other charges flat', () {
    const form = PurchaseFormState(
        discount: 100, vatPercent: 10, tcsPercent: 1, otherCharges: 50, loadingFreight: 20);
    // goods = 1100 − 100 = 1000 → VAT 100 → TCS 1% of 1100 = 11.
    expect(form.vatAmount(1100), 100);
    expect(form.tcsAmount(1100), 11);
    expect(form.extraCharges(1100), 100 + 11 + 50 + 20 - 100);
    // Percent applied to a non-round base rounds to paise.
    expect(const PurchaseFormState(vatPercent: 12.5).vatAmount(333.33), 41.67);
  });

  group('import templates', () {
    test('each template re-imports with its own headers and nothing else', () async {
      final env = await TestEnv.create(fileBacked: false);
      addTearDown(env.dispose);
      final container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(env.db)]);
      addTearDown(container.dispose);
      final importer = container.read(masterImportServiceProvider);

      for (final target in MasterImportTarget.values) {
        final bytes = MasterTemplateService().build(target, categories: ['Strong Beer', 'Mild Beer']);
        final file = XFile.fromData(Uint8List.fromList(bytes), name: 'template.xlsx');
        final rows = await importer.readRows(file);
        expect(rows.first, MasterTemplateService.headers[target], reason: '$target header row');
        expect(rows.length, 1, reason: '$target template must not carry sample data');
      }
    });

    test('filled materials template imports; missing category is rejected', () async {
      final env = await TestEnv.create(fileBacked: false);
      addTearDown(env.dispose);
      final container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(env.db)]);
      addTearDown(container.dispose);

      final csv = [
        MasterTemplateService.headers[MasterImportTarget.materials]!.join(','),
        'KS-650,KINGFISHER STRONG,United Breweries,Strong Beer,650 ML,190,0,',
        'KM-650,KINGFISHER PREMIUM,United Breweries,,650 ML,170,0,',
      ].join('\n');
      final summary = await container.read(masterImportServiceProvider).importFile(
            MasterImportTarget.materials,
            XFile.fromData(Uint8List.fromList(csv.codeUnits), name: 'materials.csv', path: 'materials.csv'),
          );
      expect(summary.imported, 1);
      expect(summary.failed, 1);
      expect(summary.errors.single, contains('Category is required'));
    });
  });
}
