import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/backup_service.dart';
import 'package:pos_app/core/local/material_lookup_cache.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/masters/data/models/save_license_holder_request.dart';
import 'package:pos_app/features/onboarding/data/opening_stock_service.dart';
import 'package:pos_app/features/sales/presentation/cart_controller.dart';
import 'package:pos_app/features/sales/presentation/sales_checkout_service.dart';
import 'package:pos_app/features/sales/presentation/sales_providers.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sql;

import 'support/test_env.dart';

void main() {
  test('P1: onboarding a new beer with no type is reported, not silently Mild', () {
    final rows = OpeningStockService.parseRows([
      ['SCM Code', 'Brand Name', 'Category', 'Size', 'Closing Stock'],
      ['SCMB1', 'NEW BEER', 'Beer', '650 ML', '10'],
      ['SCMB2', 'STRONG ONE', 'Strong Beer', '650 ML', '5'],
    ]);
    final m = OpeningStockService.match(rows, const []);
    expect(m.newProducts.map((r) => r.code), ['SCMB2']);
    expect(m.problems.single, contains('NEW BEER'));
  });

  test('P2: a backup from a newer Caskly version is refused', () async {
    final env = await TestEnv.create(fileBacked: true);
    addTearDown(env.dispose);
    final dir = await Directory.systemTemp.createTemp('bk');
    final file = await BackupService(env.db).backupNow(targetFolder: dir.path);
    final db = sql.sqlite3.open(file.path);
    db.execute('PRAGMA user_version = 999');
    db.close();
    expect(BackupService.validateBackup(file), contains('newer'));
  });

  test('P3: billing a One Time permit does not skip the next holder in rotation', () async {
    final env = await TestEnv.create(fileBacked: false);
    addTearDown(env.dispose);
    await env.addMaterial('M1', stock: 50);
    final c = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(env.db)]);
    addTearDown(c.dispose);
    final repo = c.read(mastersRepositoryProvider);
    await repo.createLicenseHolder(const SaveLicenseHolderRequest(permitNo: 'A-OT', name: 'A', validity: 'One Time'));
    await repo.createLicenseHolder(const SaveLicenseHolderRequest(permitNo: 'B', name: 'B'));
    await repo.createLicenseHolder(const SaveLicenseHolderRequest(permitNo: 'C', name: 'C'));
    c.read(materialLookupCacheProvider.notifier).state = await MaterialLookupCache.load(env.db);
    final sub = c.listen(activeLicenseHolderProvider, (_, __) {});
    addTearDown(sub.close);
    await c.read(rotationLicenseHoldersProvider.future);
    expect(c.read(activeLicenseHolderProvider)?.permitNo, 'A-OT');
    await c.read(cartControllerProvider.notifier).addByBarcode('BC-M1');
    await c.read(salesCheckoutServiceProvider).executeCheckout();
    await c.read(rotationLicenseHoldersProvider.future);
    expect(c.read(activeLicenseHolderProvider)?.permitNo, 'B');
  });
}
