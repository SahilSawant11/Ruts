// First-run setup: a new store enters its closing stock from the old
// system, then bills. Day one's brandwise report must open on exactly that
// stock, without any change to the report code.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/masters/data/master_import_service.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/onboarding/data/opening_stock_service.dart';
import 'package:pos_app/features/reports/data/brandwise_report_provider.dart';

import 'support/test_env.dart';

void main() {
  group('closing stock sheet', () {
    test('reads common column names; blanks are 0; bad rows are reported', () {
      final problems = <String>[];
      final rows = OpeningStockService.parseRows([
        ['Sr', 'SCM Code', 'Brand Name', 'Size', 'Category', 'MRP', 'Closing Stock'],
        ['1', 'M1', 'Item M1', '750 ML', 'Whisky', '1,200', '24'],
        ['2', 'M2', 'Item M2', '750 ML', 'Whisky', '900', ''],
        ['3', 'M3', 'Item M3', '750 ML', 'Whisky', '900', '12.0'],
        ['4', 'M4', 'Item M4', '750 ML', 'Whisky', '900', '2.5'],
        ['5', 'M5', 'Item M5', '750 ML', 'Whisky', '900', '-3'],
        ['', '', 'TOTAL', '', '', '', '36'],
        ['', '', '', '', '', '', ''],
      ], problems: problems);

      // TOTAL has a name, so it is kept as a row; matching rejects it.
      expect(rows.map((r) => r.code), ['M1', 'M2', 'M3', '']);
      expect(rows.map((r) => r.qty), [24, 0, 12, 36]);
      expect(rows.first.saleRate, 1200);
      expect(problems, hasLength(2));
      expect(problems[0], contains('Row 5'));
      expect(problems[1], contains('negative'));
    });

    test('a sheet without a quantity column is refused with a clear message', () {
      expect(
        () => OpeningStockService.parseRows([
          ['SCM Code', 'Brand Name'],
          ['M1', 'Item M1'],
        ]),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Closing Stock'))),
      );
    });
  });

  test('matching: code, barcode, name+size, duplicates summed, new products, problems', () async {
    final env = await TestEnv.create(fileBacked: false);
    addTearDown(env.dispose);
    for (final id in ['M1', 'M2', 'M3']) {
      await env.addMaterial(id, stock: 0);
    }
    final materials = await env.masters.getMaterials();
    final rows = OpeningStockService.parseRows([
      ['SCM Code', 'Brand Name', 'Size', 'Category', 'Closing'],
      ['m1', 'whatever', '', '', '10'], // code, case-insensitive
      ['M1', '', '', '', '5'], // duplicate → summed
      ['BC-M2', '', '', '', '7'], // barcode
      ['', 'Item M3', '750 ml', '', '3'], // name + size
      ['NEW1', 'Fresh Gin', '750 ML', 'Gin', '6'], // creatable
      ['NEW2', 'No Size Rum', '', 'Rum', '4'], // not creatable
      ['', 'TOTAL', '', '', '35'],
    ]);
    final match = OpeningStockService.match(rows, materials);
    expect(match.qtyByMaterial, {'M1': 15, 'M2': 7, 'M3': 3});
    expect(match.newProducts.single.code, 'NEW1');
    expect(match.problems, hasLength(2));
    expect(match.problems.join('\n'), allOf(contains('No Size Rum'), contains('TOTAL')));
  });

  test('go-live: opening stock flows into day one of the brandwise report', () async {
    final env = await TestEnv.create(fileBacked: false);
    addTearDown(env.dispose);
    for (final id in ['M1', 'M2', 'M3']) {
      await env.addMaterial(id, stock: 0);
    }
    final service = OpeningStockService(env.db, env.masters, MasterImportService(env.masters));

    expect(await service.needsOnboarding(), isTrue);

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await service.apply(
      asOf: yesterday,
      qtyByMaterial: {'M1': 24, 'M2': 12, 'M3': 0},
      newProducts: const [
        ClosingStockRow(
            rowNumber: 2, code: 'NEW1', name: 'Fresh Gin', category: 'Gin', packing: '750 ML', saleRate: 900, qty: 6),
      ],
      enteredBy: 'owner',
    );

    expect(await service.needsOnboarding(), isFalse);
    expect(await env.stockOf('M1'), 24);
    expect(await env.stockOf('M2'), 12);
    expect(await env.stockOf('NEW1'), 6);
    expect(await env.db.getSetting(OpeningStockService.goLiveKey), isNotNull);
    expect(await env.db.getSetting(OpeningStockService.auditKey), contains('"bottles":42'));

    // Day one: sell some of it.
    await env.sales.createSale(TestEnv.sale({'M1': 5}));
    await env.sales.createSale(TestEnv.sale({'M1': 1, 'NEW1': 2}));

    final container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(env.db)]);
    addTearDown(container.dispose);
    final report = await container.read(brandwiseReportProvider.future);
    final items = [for (final c in report.categories) ...c.items];
    final opening = items.fold<int>(0, (s, i) => s + i.openingBalance.total);
    final sale = items.fold<int>(0, (s, i) => s + i.sale.total);
    final closing = items.fold<int>(0, (s, i) => s + i.closingBalance.total);

    expect(opening, 42, reason: 'day one must open on the entered closing stock');
    expect(sale, 8);
    expect(closing, 34);
  });

  test('a store that already has bills never sees setup', () async {
    final env = await TestEnv.create(fileBacked: false);
    addTearDown(env.dispose);
    await env.addMaterial('M1', stock: 10);
    await env.sales.createSale(TestEnv.sale({'M1': 1}));
    final service = OpeningStockService(env.db, env.masters, MasterImportService(env.masters));

    expect(await service.needsOnboarding(), isFalse);
    expect(await env.db.getSetting(OpeningStockService.completeKey), 'existing-data');
  });
}
