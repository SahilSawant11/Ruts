// Client follow-up 17 Nov 2026: Excel export for bill lists and masters,
// and Customer → NEW on the sales bill creating a license holder.
import 'dart:typed_data';

import 'package:excel_community/excel_community.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/material_lookup_cache.dart';
import 'package:pos_app/core/network/api_exception.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/masters/data/models/save_license_holder_request.dart';
import 'package:pos_app/features/purchase/data/models/create_purchase_request.dart';
import 'package:pos_app/features/purchase/data/purchase_bills_export.dart';
import 'package:pos_app/features/sales/data/sales_bills_export.dart';
import 'package:pos_app/features/sales/presentation/cart_controller.dart';
import 'package:pos_app/features/sales/presentation/sales_checkout_service.dart';
import 'package:pos_app/features/sales/presentation/sales_providers.dart';
import 'package:pos_app/shared/export/table_excel_exporter.dart';

import 'support/test_env.dart';

void main() {
  test('table exporter writes header + typed rows that Excel reads back', () {
    final bytes = const TableExcelExporter().build(
      sheetName: 'Bills',
      headers: const ['Bill No', 'Qty', 'Total'],
      rows: const [
        ['S-1', 3, 450.5],
        ['S-2', null, 0.0],
      ],
    );
    final sheet = Excel.decodeBytes(Uint8List.fromList(bytes)).tables['Bills']!;
    expect(sheet.rows.first.map((c) => c?.value.toString()), ['Bill No', 'Qty', 'Total']);
    expect(sheet.rows[1][1]?.value, isA<IntCellValue>());
    expect(sheet.rows[1][2]?.value, isA<DoubleCellValue>());
    expect(sheet.rows.length, 3);
  });

  test('sales and purchase bill rows carry permit, TP and charges', () async {
    final env = await TestEnv.create(fileBacked: false);
    addTearDown(env.dispose);
    await env.addMaterial('M1', stock: 50);
    await env.sales.createSale(TestEnv.sale({'M1': 2}));
    await env.purchases.createPurchase(const CreatePurchaseRequest(
      supplierId: 'SUP-1', billNo: 'INV-7', payMode: 'Credit', tpNo: 'TP-77', discount: 0, vat: 12,
      stamp: 5, tcs: 1, loadingFreight: 0, netAmount: 618, totalAmount: 618,
      lineItems: [
        CreatePurchaseLineItemRequest(
            materialId: 'M1', batchNo: 'B', qty: 6, rate: 100, disPercent: 0, disAmount: 0,
            taxPercent: 0, taxAmount: 0, amount: 600),
      ],
    ));

    final sales = await env.sales.getSalesBills();
    final saleRow = SalesBillsExport.rows(sales).single;
    expect(saleRow.length, SalesBillsExport.headers.length);
    expect(saleRow[6], 2, reason: 'bottles');

    final purchases = await env.purchases.getPurchaseBills();
    final pRow = PurchaseBillsExport.rows(purchases).single;
    expect(pRow.length, PurchaseBillsExport.headers.length);
    expect(pRow[3], 'TP-77');
    expect(pRow[7], 6);
    expect(pRow[10], 5, reason: 'Other / Breakage');
  });

  group('Customer → NEW', () {
    late TestEnv env;
    late ProviderContainer c;

    setUp(() async {
      env = await TestEnv.create(fileBacked: false);
      await env.addMaterial('M1', stock: 50);
      c = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(env.db)]);
      c.read(materialLookupCacheProvider.notifier).state = await MaterialLookupCache.load(env.db);
      await c.read(licenseHoldersListProvider.future);
      await c.read(cartControllerProvider.notifier).addByBarcode('BC-M1');
    });
    tearDown(() async {
      c.dispose();
      await env.dispose();
    });

    test('saving the bill adds the license holder and stamps it on the bill', () async {
      c.read(newPermitModeProvider.notifier).state = true;
      c.read(newPermitNameProvider.notifier).state = 'Ravi Patil';
      c.read(newPermitNoProvider.notifier).state = 'OD-2026-555';

      final result = await c.read(salesCheckoutServiceProvider).executeCheckout();
      expect(result, isNotNull);

      final holder = await (env.db.select(env.db.cachedLicenseHolders)
            ..where((t) => t.permitNo.equals('OD-2026-555')))
          .getSingle();
      expect(holder.name, 'Ravi Patil');
      final bill = await env.db.select(env.db.cachedSalesBills).getSingle();
      expect(bill.permitNo, 'OD-2026-555');
      expect(bill.permitHolderName, 'Ravi Patil');
      expect(c.read(newPermitModeProvider), isFalse, reason: 'next bill goes back to normal');
      final holders = await c.read(licenseHoldersListProvider.future);
      expect(holders.map((h) => h.permitNo), contains('OD-2026-555'), reason: 'joins the rotation');
    });

    test('an existing permit number is reused, not duplicated', () async {
      await c.read(mastersRepositoryProvider).createLicenseHolder(
          const SaveLicenseHolderRequest(permitNo: 'LT-0042', name: 'Asha Kulkarni'));
      final before = await env.db.select(env.db.cachedLicenseHolders).get();
      final existing = before.firstWhere((h) => h.permitNo == 'LT-0042');
      c.read(newPermitModeProvider.notifier).state = true;
      c.read(newPermitNameProvider.notifier).state = 'Someone';
      c.read(newPermitNoProvider.notifier).state = existing.permitNo.toLowerCase();
      await c.read(salesCheckoutServiceProvider).executeCheckout();
      expect((await env.db.select(env.db.cachedLicenseHolders).get()).length, before.length);
      final bill = await env.db.select(env.db.cachedSalesBills).getSingle();
      expect(bill.permitNo, existing.permitNo);
    });

    test('missing name or number blocks the save and keeps the cart', () async {
      c.read(newPermitModeProvider.notifier).state = true;
      c.read(newPermitNameProvider.notifier).state = 'Only Name';
      await expectLater(c.read(salesCheckoutServiceProvider).executeCheckout(), throwsA(isA<ApiException>()));
      expect(c.read(cartControllerProvider).isEmpty, isFalse);
      expect(await env.db.select(env.db.cachedSalesBills).get(), isEmpty);
    });
  });
}
