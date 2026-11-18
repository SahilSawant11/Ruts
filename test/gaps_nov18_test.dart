
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/network/api_exception.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/masters/data/models/save_license_holder_request.dart';
import 'package:pos_app/features/masters/data/models/save_material_request.dart';
import 'package:pos_app/features/purchase/data/models/create_purchase_request.dart';
import 'package:pos_app/features/reports/data/counter_brandwise_report_provider.dart';
import 'package:pos_app/features/sales/data/models/create_sale_request.dart';

import 'package:pos_app/core/local/material_lookup_cache.dart';
import 'package:pos_app/features/purchase/data/purchase_providers.dart';
import 'package:pos_app/features/sales/data/sales_providers.dart';
import 'package:pos_app/features/sales/presentation/cart_controller.dart';

import 'support/test_env.dart';

SaveMaterialRequest mat(String scm, String barcode, String name,
        {String counter = '', String packing = '650 ML', String category = 'Beer', String type = 'Strong'}) =>
    SaveMaterialRequest(
        id: scm, scmCode: scm, barcode: barcode, name: name, manufacturer: 'UB', category: category,
        liquorType: type, packing: packing, saleRate: 100, taxPercent: 0, counterBrandName: counter);

void main() {
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

  Future<void> buy(String id, int qty, {String? tp}) => env.purchases.createPurchase(CreatePurchaseRequest(
        supplierId: 'SUP-1', billNo: 'INV-${DateTime.now().microsecondsSinceEpoch}', payMode: 'Credit', tpNo: tp,
        discount: 0, vat: 0, stamp: 0, tcs: 0, loadingFreight: 0, netAmount: 0, totalAmount: 0,
        lineItems: [
          CreatePurchaseLineItemRequest(materialId: id, batchNo: 'B', qty: qty, rate: 100, disPercent: 0,
              disAmount: 0, taxPercent: 0, taxAmount: 0, amount: qty * 100.0),
        ],
      ));

  test('A: editing a material into an existing SCM+barcode pair is refused', () async {
    await env.masters.createMaterial(mat('SCM1', '111', 'KF'));
    final b = await env.masters.createMaterial(mat('SCM1', '222', 'KF'));
    expect(b.id, 'SCM1/222');
    await expectLater(env.masters.updateMaterial(b.id, mat('SCM1', '111', 'KF')), throwsA(isA<ApiException>()));
  });

  test('B: new holder with a permit no that an edited holder used to have does not overwrite it', () async {
    await env.masters.createLicenseHolder(const SaveLicenseHolderRequest(permitNo: 'P-1', name: 'RAMA'));
    await env.masters.updateLicenseHolder('P-1', const SaveLicenseHolderRequest(permitNo: 'P-2', name: 'RAMA'));
    await env.masters.createLicenseHolder(const SaveLicenseHolderRequest(permitNo: 'P-1', name: 'PATIL'));
    final all = await env.masters.getLicenseHolders();
    expect(all.map((h) => '${h.permitNo}:${h.name}').toSet(), {'P-2:RAMA', 'P-1:PATIL'});
  });

  test('F: counter brand names differing only by case are one counter-brand line', () async {
    final a = await env.masters.createMaterial(mat('SCM1', '111', 'KF A', counter: 'Kingfisher Strong'));
    final b = await env.masters.createMaterial(mat('SCM2', '222', 'KF B', counter: 'KINGFISHER STRONG'));
    expect(a.counterBrandId, b.counterBrandId);
    await buy(a.id, 5);
    await buy(b.id, 7);
    final r = await c.read(counterBrandwiseReportProvider.future);
    final strong = r.categories.firstWhere((x) => x.name == 'STRONG BEER').items;
    expect(strong.where((i) => !i.isTpContinuation).length, 1, reason: strong.map((i) => i.manufacturerName).join(' | '));
  });

  test('N: the same TP number cannot be entered twice', () async {
    await env.masters.createMaterial(mat('SCM1', '111', 'KF'));
    await buy('SCM1', 5, tp: 'TP-1');
    await expectLater(buy('SCM1', 5, tp: 'TP-1'), throwsA(isA<ApiException>()));
  });

  test('S: stock on a shared-barcode material stays per row after a spilled sale is returned', () async {
    final a = await env.masters.createMaterial(mat('SCM1', '111', 'KF'));
    final b = await env.masters.createMaterial(mat('SCM2', '111', 'KF'));
    await buy(a.id, 2);
    await buy(b.id, 2);
    final bill = await env.sales.createSale(TestEnv.sale({a.id: 2, b.id: 1}));
    await env.sales.returnSalesBill(bill.id);
    expect(await env.stockOf(a.id), 2);
    expect(await env.stockOf(b.id), 2);
  });

  test('U: updating a material keeps its stock', () async {
    final a = await env.masters.createMaterial(mat('SCM1', '111', 'KF'));
    await buy(a.id, 9);
    await env.masters.updateMaterial(a.id, mat('SCM1', '111', 'KF renamed'));
    expect(await env.stockOf(a.id), 9);
    final m = (await env.masters.getMaterials()).single;
    expect(m.stockQty, 9);
  });

  test('C1: a purchase refreshes the stock Sales sees (no restart needed)', () async {
    final m = await env.masters.createMaterial(mat('SCM1', '111', 'KF'));
    c.read(materialLookupCacheProvider.notifier).state = await MaterialLookupCache.load(env.db);
    await c.read(purchaseRepositoryProvider).createPurchase(CreatePurchaseRequest(
        supplierId: 'SUP-1', billNo: 'INV-1', payMode: 'Credit', discount: 0, vat: 0, stamp: 0, tcs: 0,
        loadingFreight: 0, netAmount: 0, totalAmount: 0,
        lineItems: [
          CreatePurchaseLineItemRequest(materialId: m.id, batchNo: 'B', qty: 6, rate: 100, disPercent: 0,
              disAmount: 0, taxPercent: 0, taxAmount: 0, amount: 600),
        ]));
    expect(await c.read(cartControllerProvider.notifier).addByBarcode('111'), isTrue,
        reason: c.read(cartControllerProvider).scanError);
  });

  test('C2: a sales return refreshes the stock Sales sees', () async {
    final m = await env.masters.createMaterial(mat('SCM1', '111', 'KF'));
    await buy(m.id, 1);
    final bill = await env.sales.createSale(TestEnv.sale({m.id: 1}));
    c.read(materialLookupCacheProvider.notifier).state = await MaterialLookupCache.load(env.db);
    await c.read(salesRepositoryProvider).returnSalesBill(bill.id);
    expect(await c.read(cartControllerProvider.notifier).addByBarcode('111'), isTrue,
        reason: c.read(cartControllerProvider).scanError);
  });

  test('I: an inactive material cannot be billed', () async {
    final m = await env.masters.createMaterial(mat('SCM1', '111', 'KF'));
    await buy(m.id, 5);
    await env.masters.updateMaterial(m.id, SaveMaterialRequest(
        id: m.id, scmCode: 'SCM1', barcode: '111', name: 'KF', manufacturer: 'UB', category: 'Beer', liquorType: 'Strong',
        packing: '650 ML', saleRate: 100, taxPercent: 0, isActive: false));
    c.read(materialLookupCacheProvider.notifier).state = await MaterialLookupCache.load(env.db);
    expect(await c.read(cartControllerProvider.notifier).addByBarcode('111'), isFalse);
  });

  test('O: a One Time permit comes back into rotation when its bill is returned', () async {
    final m = await env.masters.createMaterial(mat('SCM1', '111', 'KF'));
    await buy(m.id, 5);
    await env.masters.createLicenseHolder(const SaveLicenseHolderRequest(permitNo: 'OT-1', name: 'X', validity: 'One Time'));
    final base = TestEnv.sale({m.id: 1});
    final bill = await env.sales.createSale(CreateSaleRequest(
        billNo: 'b', payMode: 'Cash', taxableValue: base.taxableValue, totalDiscount: 0, totalTax: 0,
        totalAmount: base.totalAmount, balanceDue: base.balanceDue, lineItems: base.lineItems, permitNo: 'OT-1'));
    expect((await env.masters.getRotationLicenseHolders()).map((h) => h.permitNo), isNot(contains('OT-1')));
    await env.sales.returnSalesBill(bill.id);
    expect((await env.masters.getRotationLicenseHolders()).map((h) => h.permitNo), contains('OT-1'));
  });
}
