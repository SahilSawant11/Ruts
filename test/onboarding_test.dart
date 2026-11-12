// First-run setup: a new store enters its closing stock from the old
// system, then bills. Day one's brandwise report must open on exactly that
// stock, without any change to the report code.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/masters/data/master_import_service.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/onboarding/data/opening_stock_service.dart';
import 'package:pos_app/features/onboarding/data/brandwise_stock_parser.dart';
import 'package:pos_app/features/reports/data/brandwise_excel_exporter.dart';
import 'package:pos_app/features/reports/data/brandwise_report_provider.dart';
import 'package:pos_app/features/reports/data/models/brandwise_report_dto.dart';
import 'package:pos_app/features/sales/data/models/material_dto.dart';
import 'package:pos_app/features/sales/presentation/cart_controller.dart';

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

  group('brandwise report upload', () {
    const zero = BrandwiseSizeQty();
    BrandwiseReportItemDto item(String brand, {BrandwiseSizeQty opening = zero, BrandwiseSizeQty sale = zero,
            BrandwiseSizeQty closing = zero}) =>
        BrandwiseReportItemDto(brandName: brand, openingBalance: opening, purchase: zero, sale: sale, closingBalance: closing);
    const sub = BrandwiseCategorySubtotal(openingBalance: zero, purchase: zero, sale: zero, closingBalance: zero);
    final report = BrandwiseReportDto(
      reportDate: DateTime(2026, 11, 30),
      licenseHeader: 'BEER A : WINE BR. II BRANDWISE STOCK REPORT',
      categories: [
        BrandwiseCategoryDto(name: 'FERMENTED BEER', subtotal: sub, items: [
          item('KINGFISHER STRONG', closing: const BrandwiseSizeQty(beer650: 120, beer500Can: 48)),
          // Sold out by closing: still added (with 0) so it can be purchased.
          item('TUBORG STRONG', opening: const BrandwiseSizeQty(beer650: 12), sale: const BrandwiseSizeQty(beer650: 12)),
        ]),
        BrandwiseCategoryDto(name: 'MILD BEER', subtotal: sub, items: [
          item('BUDWEISER', closing: const BrandwiseSizeQty(beer330Can: 24, beer330Bottle: 36)),
        ]),
        BrandwiseCategoryDto(name: 'WINE', subtotal: sub, items: [
          item('SULA SHIRAZ', closing: const BrandwiseSizeQty(wine750: 9, wine375: 4)),
        ]),
      ],
    );

    test("Caskly's own export reads back as products with closing stock", () {
      final rows = MasterImportService.readSpreadsheetMl(BrandwiseExcelExporter().buildWorkbook(report));
      final problems = <String>[];
      final parsed = OpeningStockService.parseRows(rows, problems: problems);
      expect(problems, isEmpty);
      String key(ClosingStockRow r) => '${r.name}|${r.packing}|${r.category}|${r.qty}';
      expect(parsed.map(key), unorderedEquals([
        'KINGFISHER STRONG|650 ML|Fermented Beer|120',
        'KINGFISHER STRONG|500 ML (CAN)|Fermented Beer|48',
        'TUBORG STRONG|650 ML|Fermented Beer|0',
        'BUDWEISER|330 ML (CAN)|Mild Beer|24',
        'BUDWEISER|330 ML|Mild Beer|36',
        'SULA SHIRAZ|750 ML|Wine|9',
        'SULA SHIRAZ|375 ML|Wine|4',
      ]));
      expect(parsed.first.code, 'KINGFISHERSTRONG-650');
      expect(BrandwiseStockParser.codeFor('BUDWEISER', '330 ML (CAN)'), 'BUDWEISER-330C');
    });

    test('go-live from the upload: day one report opens on the uploaded closing', () async {
      final env = await TestEnv.create(fileBacked: false);
      addTearDown(env.dispose);
      final service = OpeningStockService(env.db, env.masters, MasterImportService(env.masters));
      final rows = MasterImportService.readSpreadsheetMl(BrandwiseExcelExporter().buildWorkbook(report));
      final match = OpeningStockService.match(OpeningStockService.parseRows(rows), await env.masters.getMaterials());
      expect(match.problems, isEmpty);
      expect(match.newProducts, hasLength(7));

      await service.apply(
        asOf: DateTime.now().subtract(const Duration(days: 1)),
        qtyByMaterial: match.qtyByMaterial,
        newProducts: match.newProducts,
        enteredBy: 'owner',
      );

      final container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(env.db)]);
      addTearDown(container.dispose);
      final today = await container.read(brandwiseReportProvider.future);
      final byName = {for (final c in today.categories) for (final i in c.items) i.brandName: i};
      expect(byName['KINGFISHER STRONG']!.openingBalance.beer650, 120);
      expect(byName['KINGFISHER STRONG']!.openingBalance.beer500Can, 48);
      expect(byName['BUDWEISER']!.openingBalance.beer330Can, 24);
      expect(byName['BUDWEISER']!.openingBalance.beer330Bottle, 36);
      expect(byName['SULA SHIRAZ']!.openingBalance.wine750, 9);
      expect(byName['SULA SHIRAZ']!.openingBalance.wine375, 4);
      final cats = {for (final c in today.categories) c.name: c.items.map((i) => i.brandName).toSet()};
      expect(cats['FERMENTED BEER'], contains('KINGFISHER STRONG'));
      expect(cats['MILD BEER'], contains('BUDWEISER'));
      expect(cats['WINE'], contains('SULA SHIRAZ'));

      // Re-importing the same report matches the same products.
      final again = OpeningStockService.match(OpeningStockService.parseRows(rows), await env.masters.getMaterials());
      expect(again.newProducts, isEmpty);
      expect(again.qtyByMaterial['KINGFISHERSTRONG-650'], 120);
    });

    test('a product with no MRP yet cannot be billed at ₹0', () async {
      const m = MaterialDto(id: 'B-650', barcode: 'B-650', name: 'BUDWEISER', manufacturer: 'Budweiser',
          category: 'Mild Beer', packing: '650 ML', saleRate: 0, taxPercent: 0, stockQty: 10);
      final cart = CartController((_) => m);
      expect(await cart.addByBarcode('B-650'), isFalse);
      expect(cart.state.scanError, contains('no MRP'));
      expect(cart.state.items, isEmpty);
    });

    test('a plain one-row-per-product sheet still works', () {
      final parsed = OpeningStockService.parseRows([
        ['SCM Code', 'Brand Name', 'Closing Stock'],
        ['K1', 'Kingfisher', '10'],
      ]);
      expect(parsed.single.qty, 10);
    });
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
