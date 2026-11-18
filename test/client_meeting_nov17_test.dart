// Client meeting 17 Nov 2026: material master (SCM/barcode pairs, beer
// type, counter brand + ID, wholesale, discount), brandwise "Show all",
// and license holder master (city, validity, category, frequent buyers).
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/core/local/material_lookup_cache.dart';
import 'package:pos_app/core/network/api_exception.dart';
import 'package:pos_app/features/masters/data/liquor_type.dart';
import 'package:pos_app/features/masters/data/master_import_service.dart';
import 'package:pos_app/features/masters/data/master_template_service.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/masters/data/models/license_holder_dto.dart';
import 'package:pos_app/features/masters/data/models/save_license_holder_request.dart';
import 'package:pos_app/features/masters/data/models/save_material_request.dart';
import 'package:pos_app/features/reports/data/brandwise_report_provider.dart';
import 'package:pos_app/features/reports/data/counter_brandwise_report_provider.dart';
import 'package:pos_app/features/sales/data/models/create_sale_request.dart';
import 'package:pos_app/features/sales/presentation/cart_controller.dart';
import 'package:pos_app/features/sales/presentation/sales_checkout_service.dart';
import 'package:pos_app/features/sales/presentation/sales_providers.dart';

import 'support/test_env.dart';

SaveMaterialRequest _kf(String scm, String barcode, String name, {String counter = 'Kingfisher Strong'}) =>
    SaveMaterialRequest(
      id: scm,
      barcode: barcode,
      name: name,
      manufacturer: 'UB Group',
      category: 'Beer',
      liquorType: 'Strong',
      packing: '650 ML',
      counterBrandName: counter,
      saleRate: 190,
      wholesaleRate: 170,
      taxPercent: 0,
      discountPercent: 5,
    );

/// The client's example: five bottles, one counter brand, 400 Q.
const _example = [
  ('SCM1234', '84549000', 'Kingfisher Strong', 50),
  ('SCM3756', '85458000', 'Kingfisher Strong', 100),
  ('SCM4394', '3984578456', 'Kingfisher Super Strong', 50),
  ('SCM1234', '845445889', 'Kingfisher Strong', 100),
  ('SCM4756', '85458000', 'Kingfisher Strong', 100),
];

void main() {
  test('legacy "Strong Beer" categories become Beer + type', () {
    expect(normalizeLiquorCategory('Strong Beer'), (category: 'Beer', type: 'Strong'));
    expect(normalizeLiquorCategory('Fermented Beer'), (category: 'Beer', type: 'Fermented'));
    expect(normalizeLiquorCategory('Beer', 'mild'), (category: 'Beer', type: 'Mild'));
    expect(normalizeLiquorCategory('Whisky', 'Strong'), (category: 'Whisky', type: ''));
  });

  group('material master', () {
    late TestEnv env;
    late ProviderContainer c;
    setUp(() async {
      env = await TestEnv.create(fileBacked: false);
      c = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(env.db)]);
    });
    tearDown(() async {
      c.dispose();
      await env.dispose();
    });

    Future<List<String>> addExample() async {
      final repo = c.read(mastersRepositoryProvider);
      final ids = <String>[];
      for (final (scm, barcode, name, qty) in _example) {
        final m = await repo.createMaterial(_kf(scm, barcode, name));
        ids.add(m.id);
        await env.db.into(env.db.cachedInventoryStocks).insert(CachedInventoryStocksCompanion.insert(
              materialId: m.id, barcode: barcode, name: name, category: 'Beer', qtyOnHand: qty));
      }
      return ids;
    }

    test('same SCM with another barcode is a new material; the same pair is refused', () async {
      final ids = await addExample();
      expect(ids, ['SCM1234', 'SCM3756', 'SCM4394', 'SCM1234/845445889', 'SCM4756']);
      final all = await c.read(mastersRepositoryProvider).getMaterials();
      expect(all.where((m) => m.scmCode == 'SCM1234').length, 2);
      expect(all.map((m) => m.counterBrandId).toSet(), {'CB-0001'}, reason: 'one counter brand, one ID');
      final m = all.firstWhere((m) => m.id == 'SCM4394');
      expect((m.category, m.liquorType, m.wholesaleRate, m.discountPercent), ('Beer', 'Strong', 170.0, 5.0));

      await expectLater(
        c.read(mastersRepositoryProvider).createMaterial(_kf('SCM1234', '845445889', 'dup')),
        throwsA(isA<ApiException>()),
      );
    });

    test('a new counter brand gets the next ID; the shop prefix re-prefixes all', () async {
      final repo = c.read(mastersRepositoryProvider);
      await repo.createMaterial(_kf('A1', 'A1', 'Kingfisher Strong'));
      final tuborg = await repo.createMaterial(_kf('T1', 'T1', 'Tuborg Strong', counter: ''));
      expect(tuborg.counterBrandName, 'Tuborg Strong', reason: 'blank counter brand = display name');
      expect(tuborg.counterBrandId, 'CB-0002');
      final again = await repo.createMaterial(_kf('A2', 'A2', 'KF', counter: '  kingfisher   STRONG '));
      expect(again.counterBrandId, 'CB-0001', reason: 'names match ignoring case and spaces');

      await env.db.setShopPrefix('rs');
      final ids = (await repo.getMaterials()).map((m) => m.counterBrandId).toSet();
      expect(ids, {'RS-0001', 'RS-0002'});
      final next = await repo.createMaterial(_kf('B1', 'B1', 'Budweiser Magnum', counter: ''));
      expect(next.counterBrandId, 'RS-0003');
    });

    test('counter brandwise adds the five bottles up to 400 Q', () async {
      await addExample();
      final counter = await c.read(counterBrandwiseReportProvider.future);
      final strong = counter.categories.firstWhere((x) => x.name == 'STRONG BEER').items;
      expect(strong.single.manufacturerName, 'Kingfisher Strong');
      expect(strong.single.closingBalance.beer650, 400);

      final brandwise = await c.read(brandwiseReportProvider.future);
      final rows = brandwise.categories.firstWhere((x) => x.name == 'STRONG BEER').items;
      expect({for (final r in rows) r.brandName: r.closingBalance.beer650},
          {'Kingfisher Strong': 350, 'Kingfisher Super Strong': 50});
    });

    test('"Show all" brings back zero-stock items; inactive never shows', () async {
      final repo = c.read(mastersRepositoryProvider);
      await addExample();
      await repo.createMaterial(_kf('Z1', 'Z1', 'Haywards 5000', counter: ''));
      final off = await repo.createMaterial(_kf('Z2', 'Z2', 'Old Stock', counter: ''));
      await (env.db.update(env.db.cachedMaterials)..where((t) => t.id.equals(off.id)))
          .write(const CachedMaterialsCompanion(isActive: Value(false)));

      Future<Set<String>> names() async => {
            for (final x in (await c.read(counterBrandwiseReportProvider.future)).categories)
              for (final i in x.items) i.manufacturerName,
          };
      expect(await names(), {'Kingfisher Strong'});
      c.read(brandwiseShowAllProvider.notifier).state = true;
      expect(await names(), {'Kingfisher Strong', 'Haywards 5000'});
    });

    test('a shared barcode bills the row with stock, then moves to the next row', () async {
      await addExample();
      final cache = await MaterialLookupCache.load(env.db);
      expect(cache.findByBarcodeOrId('85458000')!.stockQty, 100);
      expect(cache.allForCode('85458000').map((m) => m.id).toSet(), {'SCM3756', 'SCM4756'});

      final cart = CartController(cache.findByBarcodeOrId, cache.allForCode);
      // 12-bottle legal limit per bill, so shrink one row to show the spill.
      await env.db.customStatement("UPDATE cached_inventory_stocks SET qty_on_hand = 2 WHERE material_id IN ('SCM3756', 'SCM4756')");
      final small = await MaterialLookupCache.load(env.db);
      final cart2 = CartController(small.findByBarcodeOrId, small.allForCode);
      expect(await cart.addByBarcode('85458000'), isTrue);
      expect(cart.state.items.single.discountPercent, 5, reason: 'discount comes from the master');
      for (var i = 0; i < 3; i++) {
        expect(await cart2.addByBarcode('85458000'), isTrue);
      }
      final byMaterial = {for (final i in cart2.state.items) i.materialId: i.qty};
      expect(byMaterial.values.fold<int>(0, (a, b) => a + b), 3);
      expect(byMaterial.length, 2, reason: 'third bottle came from the other SCM row');
    });

    test('v17 migration: beer categories split, counter brands from manufacturer, Life Time → validity', () async {
      final db = env.db;
      await env.addMaterial('OLD1');
      await db.customStatement(
          "UPDATE cached_materials SET category = 'Fermented Beer', manufacturer = 'KF Strong', scm_code = '', "
          "counter_brand_name = '', counter_brand_id = '' WHERE id = 'OLD1'");
      await db.into(db.cachedLicenseHolders).insert(CachedLicenseHoldersCompanion.insert(
          id: 'P1', permitNo: 'P1', name: 'A', whereGranted: const Value('Life Time')));
      await db.into(db.cachedLicenseHolders).insert(CachedLicenseHoldersCompanion.insert(
          id: 'P2', permitNo: 'P2', name: 'B', whereGranted: const Value('Pune')));

      await db.runV17MigrationForTest();

      final m = await (db.select(db.cachedMaterials)..where((t) => t.id.equals('OLD1'))).getSingle();
      expect((m.scmCode, m.category, m.liquorType, m.counterBrandName, m.counterBrandId),
          ('OLD1', 'Beer', 'Fermented', 'KF Strong', 'CB-0001'));
      final holders = {for (final h in await db.select(db.cachedLicenseHolders).get()) h.id: h};
      expect((holders['P1']!.validity, holders['P1']!.city), ('Lifetime', null));
      expect((holders['P2']!.validity, holders['P2']!.city), ('Lifetime', 'Pune'));
    });

    test('new material template imports with type, counter brand and rates', () async {
      final csv = [
        MasterTemplateService.headers[MasterImportTarget.materials]!.join(','),
        'SCM1234,84549000,KINGFISHER STRONG,Beer,Strong,650 ML,UB Group,KINGFISHER STRONG,190,170,0,5',
        'SCM1234,845445889,KINGFISHER STRONG,Beer,Strong,650 ML,UB Group,KINGFISHER STRONG,190,170,0,5',
        'SCM4394,3984578456,KINGFISHER SUPER STRONG,Strong Beer,,650 ML,UB Group,Kingfisher Strong,200,,0,',
        'SCM9999,,BUDWEISER,Beer,,650 ML,AB InBev,,200,,0,',
      ].join('\n');
      final summary = await c.read(masterImportServiceProvider).importFile(
            MasterImportTarget.materials,
            XFile.fromData(Uint8List.fromList(csv.codeUnits), name: 'm.csv', path: 'm.csv'),
          );
      expect(summary.imported, 3);
      expect(summary.errors.single, contains('Beer needs a Type'));
      final all = await c.read(mastersRepositoryProvider).getMaterials();
      expect(all.map((m) => m.counterBrandId).toSet(), {'CB-0001'});
      expect(all.firstWhere((m) => m.id == 'SCM4394').liquorType, 'Strong');
    });
  });

  group('license holders', () {
    late TestEnv env;
    late ProviderContainer c;
    setUp(() async {
      env = await TestEnv.create(fileBacked: false);
      await env.addMaterial('M1', stock: 50);
      c = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(env.db)]);
      final repo = c.read(mastersRepositoryProvider);
      await repo.createLicenseHolder(const SaveLicenseHolderRequest(permitNo: 'LT-1', name: 'Rotating Holder'));
      c.read(materialLookupCacheProvider.notifier).state = await MaterialLookupCache.load(env.db);
      await c.read(rotationLicenseHoldersProvider.future);
      await c.read(cartControllerProvider.notifier).addByBarcode('BC-M1');
    });
    tearDown(() async {
      c.dispose();
      await env.dispose();
    });

    test('frequent buyers need only a name and never rotate; used One Time permits leave', () async {
      final repo = c.read(mastersRepositoryProvider);
      final buyer = await repo.createLicenseHolder(const SaveLicenseHolderRequest(
          permitNo: '', name: 'Regular Raju', category: LicenseHolderDto.frequentBuyer, city: 'Pune'));
      expect(buyer.id, startsWith('FB-'));
      await repo.createLicenseHolder(const SaveLicenseHolderRequest(
          permitNo: 'OT-9', name: 'One Timer', validity: LicenseHolderDto.oneTime));
      expect((await repo.getRotationLicenseHolders()).map((h) => h.permitNo), unorderedEquals(['LT-1', 'OT-9']));

      final base = TestEnv.sale({'M1': 1});
      await env.sales.createSale(CreateSaleRequest(
        billNo: base.billNo,
        permitNo: 'OT-9',
        permitHolderName: 'One Timer',
        payMode: base.payMode,
        taxableValue: base.taxableValue,
        totalDiscount: 0,
        totalTax: 0,
        totalAmount: base.totalAmount,
        balanceDue: base.balanceDue,
        lineItems: base.lineItems,
      ));
      expect((await repo.getRotationLicenseHolders()).map((h) => h.permitNo), ['LT-1']);
      await expectLater(
        repo.createLicenseHolder(const SaveLicenseHolderRequest(permitNo: '', name: 'No Permit')),
        throwsA(isA<ApiException>()),
        reason: 'license holders still need a permit',
      );
    });

    test('New → Walk in saves a One Time permit issued today', () async {
      c.read(newPermitModeProvider.notifier).state = true;
      c.read(newPermitNameProvider.notifier).state = 'Walk In Wala';
      c.read(newPermitNoProvider.notifier).state = 'WI-77';
      await c.read(salesCheckoutServiceProvider).executeCheckout();
      final h = await (env.db.select(env.db.cachedLicenseHolders)..where((t) => t.permitNo.equals('WI-77'))).getSingle();
      expect(h.validity, LicenseHolderDto.oneTime);
      expect(h.category, LicenseHolderDto.licenseHolder);
      expect(h.issuedDate, matches(RegExp(r'^\d\d-[A-Z][a-z]{2}-\d{4}$')));
      final rotation = await c.read(rotationLicenseHoldersProvider.future);
      expect(rotation.map((x) => x.permitNo), isNot(contains('WI-77')));
    });

    test('New → Frequent Buyer saves the name; the bill keeps the rotating permit', () async {
      c.read(newPermitModeProvider.notifier).state = true;
      c.read(newFrequentBuyerProvider.notifier).state = true;
      c.read(newPermitNameProvider.notifier).state = 'Sunil Regular';
      await c.read(salesCheckoutServiceProvider).executeCheckout();
      final buyer = await (env.db.select(env.db.cachedLicenseHolders)
            ..where((t) => t.name.equals('Sunil Regular')))
          .getSingle();
      expect((buyer.category, buyer.permitNo), (LicenseHolderDto.frequentBuyer, ''));
      final bill = await env.db.select(env.db.cachedSalesBills).getSingle();
      expect(bill.permitNo, 'LT-1');
      expect(bill.customerId, buyer.id);
      expect((await c.read(frequentBuyersProvider.future)).single.name, 'Sunil Regular');
    });
  });
}
