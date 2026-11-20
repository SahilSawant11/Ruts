// High-risk scenarios added 20 Nov: material number limits and the
// bill-number switch at the start of a financial year.
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' show XFile;
import 'package:go_router/go_router.dart';
import 'package:pos_app/app/router.dart';
import 'package:pos_app/core/auth/app_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/core/network/api_exception.dart';
import 'package:pos_app/features/masters/data/master_import_service.dart';
import 'package:pos_app/features/masters/data/master_template_service.dart';
import 'package:pos_app/features/masters/data/models/license_holder_dto.dart';
import 'package:pos_app/features/masters/data/models/save_license_holder_request.dart';
import 'package:pos_app/features/masters/data/models/save_material_request.dart';
import 'package:pos_app/features/masters/data/models/save_supplier_request.dart';
import 'package:pos_app/features/masters/data/models/supplier_dto.dart';
import 'package:pos_app/features/purchase/presentation/purchase_form_controller.dart';

import 'support/test_env.dart';

SaveMaterialRequest _mat(String id, {double rate = 100, double wholesale = 0, double dis = 0, double tax = 0}) =>
    SaveMaterialRequest(
        id: id, scmCode: id, barcode: 'BC$id', name: 'Item $id', manufacturer: 'UB', category: 'Wine',
        liquorType: '', packing: '750 ML', saleRate: rate, wholesaleRate: wholesale, taxPercent: tax,
        discountPercent: dis, counterBrandName: '');

void main() {
  late TestEnv env;
  setUp(() async => env = await TestEnv.create(fileBacked: false));
  tearDown(() async => env.dispose());

  group('material numbers', () {
    test('discount over 100% or below 0 is refused', () async {
      await expectLater(env.masters.createMaterial(_mat('A', dis: 150)), throwsA(isA<ApiException>()));
      await expectLater(env.masters.createMaterial(_mat('A', dis: -1)), throwsA(isA<ApiException>()));
      expect((await env.masters.createMaterial(_mat('A', dis: 100))).discountPercent, 100);
    });

    test('negative rates or tax are refused, on create and on edit', () async {
      await expectLater(env.masters.createMaterial(_mat('A', rate: -5)), throwsA(isA<ApiException>()));
      await expectLater(env.masters.createMaterial(_mat('A', wholesale: -5)), throwsA(isA<ApiException>()));
      await expectLater(env.masters.createMaterial(_mat('A', tax: -5)), throwsA(isA<ApiException>()));
      final a = await env.masters.createMaterial(_mat('A'));
      await expectLater(env.masters.updateMaterial(a.id, _mat('A', dis: 101)), throwsA(isA<ApiException>()));
    });
  });

  group('bill numbers across 1 April', () {
    test('a new financial year starts again at 000001; the old year keeps counting', () async {
      final march = DateTime(2027, 3, 31, 23, 59);
      final april = DateTime(2027, 4, 1, 0, 1);
      expect(await env.db.reserveNextSalesBillNo(march), 'CS-2627-000001');
      expect(await env.db.reserveNextSalesBillNo(march), 'CS-2627-000002');
      expect(await env.db.peekNextSalesBillNo(april), 'CS-2728-000001');
      expect(await env.db.reserveNextSalesBillNo(april), 'CS-2728-000001');
      expect(await env.db.reserveNextSalesBillNo(march), 'CS-2627-000003', reason: 'each year has its own counter');
      expect(AppDatabase.financialYearCode(DateTime(2099, 12, 31)), '9900');
    });
  });

  group('permit holder import', () {
    Future<MasterImportSummary> importHolders(List<String> rows) => MasterImportService(env.masters).importFile(
        MasterImportTarget.licenseHolders,
        XFile.fromData(
            Uint8List.fromList(
                [MasterTemplateService.headers[MasterImportTarget.licenseHolders]!.join(','), ...rows].join('\n').codeUnits),
            name: 'h.csv',
            path: 'h.csv'));

    Future<Map<String, String>> permitByName() async =>
        {for (final h in await env.masters.getLicenseHolders()) h.name: h.permitNo};

    test('an edited holder is not replaced by a new holder given their old permit no', () async {
      final suresh = await env.masters.createLicenseHolder(const SaveLicenseHolderRequest(permitNo: 'LT-2', name: 'SURESH JADHAV'));
      await env.masters.updateLicenseHolder(suresh.id, const SaveLicenseHolderRequest(permitNo: 'LT-2B', name: 'SURESH JADHAV'));

      final s = await importHolders(['LT-2,NEW HOLDER NITIN,,Pune,Lifetime,,,,License Holder']);
      expect(s.imported, 1);
      expect(await permitByName(), {'SURESH JADHAV': 'LT-2B', 'NEW HOLDER NITIN': 'LT-2'});
    });

    test('re-importing updates holders in place, never duplicates', () async {
      await importHolders([
        'LT-1,RAMESH PATIL,,Pune,Lifetime,,,,License Holder',
        ',REGULAR RAJU,,,,,,,Frequent Buyer',
      ]);
      final before = {for (final h in await env.masters.getLicenseHolders()) h.name: h.id};
      await importHolders([
        'lt-1,RAMESH PATIL,,Nashik,Lifetime,,98xxxxxx10,,License Holder',
        ',regular raju,,,,,,VIP,Frequent Buyer',
      ]);
      final after = await env.masters.getLicenseHolders();
      expect(after.length, 2);
      final ramesh = after.firstWhere((h) => h.permitNo.toLowerCase() == 'lt-1');
      expect(ramesh.id, before['RAMESH PATIL'], reason: 'same holder, same id');
      expect(ramesh.city, 'Nashik');
      final raju = after.firstWhere((h) => h.category == LicenseHolderDto.frequentBuyer);
      expect(raju.id, before['REGULAR RAJU']);
      expect(raju.remark, 'VIP');
    });

    test('the same permit twice in one sheet is one holder', () async {
      await importHolders([
        'LT-9,FIRST NAME,,,Lifetime,,,,License Holder',
        'LT-9,SECOND NAME,,,Lifetime,,,,License Holder',
      ]);
      final all = await env.masters.getLicenseHolders();
      expect(all.length, 1);
      expect(all.single.name, 'SECOND NAME', reason: 'the later row wins');
    });
  });

  group('cashier access', () {
    List<String> paths(List<RouteBase> routes) => [
          for (final r in routes) ...[
            if (r is GoRoute) r.path,
            ...paths(r.routes),
            if (r is StatefulShellRoute) for (final b in r.branches) ...paths(b.routes),
          ],
        ];

    test('a cashier can open only Sales, Sales Return, Inventory and Settings', () {
      final router = buildAppRouter(UserRole.cashier);
      final all = paths(router.configuration.routes).toSet();
      expect(all.length, greaterThanOrEqualTo(17), reason: 'every screen in the app: $all');
      final open = all.where((p) => Permissions.canOpen(UserRole.cashier, p)).toSet();
      expect(open, {'/sales', '/sales-return', '/inventory', '/settings'});
      router.dispose();
    });

    test('inside Settings a cashier cannot back up, restore or manage users', () {
      expect(Permissions.canBackup(UserRole.cashier), isFalse);
      expect(Permissions.canRestoreBackup(UserRole.cashier), isFalse);
      expect(Permissions.canManageUsers(UserRole.cashier), isFalse);
      expect(Permissions.canRestoreBackup(UserRole.manager), isFalse, reason: 'restore is owner-only');
      expect(Permissions.canManageUsers(UserRole.owner), isTrue);
    });
  });

  group('supplier discount and import', () {
    const magnum = SupplierDto(id: 'SUP-M', name: 'Magnum Traders', disPercent: 2.5, openingBalance: 0, balanceType: 'Credit');
    const other = SupplierDto(id: 'SUP-O', name: 'Other', disPercent: 4, openingBalance: 0, balanceType: 'Credit');

    test('a purchase line starts with the chosen supplier\'s discount', () {
      expect(supplierLineDiscount(selectedSupplierId: 'SUP-O', defaultSupplierId: 'SUP-M', suppliers: [magnum, other]), 4);
      expect(supplierLineDiscount(selectedSupplierId: null, defaultSupplierId: 'SUP-M', suppliers: [magnum, other]), 2.5,
          reason: 'no supplier yet: the drink\'s default distributor');
      expect(supplierLineDiscount(selectedSupplierId: null, defaultSupplierId: '', suppliers: [magnum]), 0);
      expect(supplierLineDiscount(selectedSupplierId: 'SUP-X', defaultSupplierId: '', suppliers: [magnum]), 0);
      expect(supplierLineDiscount(selectedSupplierId: 'SUP-M', defaultSupplierId: '', suppliers: null), 0);
    });

    Future<MasterImportSummary> importSuppliers(List<String> rows) => MasterImportService(env.masters).importFile(
        MasterImportTarget.suppliers,
        XFile.fromData(
            Uint8List.fromList(
                [MasterTemplateService.headers[MasterImportTarget.suppliers]!.join(','), ...rows].join('\n').codeUnits),
            name: 's.csv',
            path: 's.csv'));

    test('re-importing suppliers updates them; blank cells keep values; unchanged rows skip', () async {
      await env.masters.createSupplier(const SaveSupplierRequest(
          name: 'Magnum Traders', address: 'Pune', contactNo: '111', disPercent: 2, openingBalance: 500, balanceType: 'Credit'));
      final s = await importSuppliers([
        'magnum traders,,222,,,,3.5,,',
        'New Dist,Nashik,,,,,1,0,Credit',
      ]);
      expect((s.imported, s.updated, s.skipped, s.failed), (1, 1, 0, 0));
      final all = await env.masters.getSuppliers();
      expect(all.length, 2);
      final m = all.firstWhere((x) => x.name == 'Magnum Traders');
      expect((m.address, m.contactNo, m.disPercent, m.openingBalance), ('Pune', '222', 3.5, 500));

      final again = await importSuppliers(['Magnum Traders,,222,,,,3.5,,']);
      expect((again.updated, again.skipped), (0, 1), reason: 'nothing changed');
    });
  });
}
