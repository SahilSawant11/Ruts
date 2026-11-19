// End-to-end run of the real Caskly app (Caskly Test Run checklist).
//
//   flutter test integration_test/app_flow_test.dart -d macos
//
// Runs against a throwaway store in a temp folder — never the real data.
// Writes build/e2e_report.json with one result per checklist step.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pos_app/app/app.dart';
import 'package:pos_app/core/local/db_paths.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/masters/data/models/save_manufacturer_request.dart';
import 'package:pos_app/features/masters/data/models/save_packaging_request.dart';
import 'package:pos_app/features/masters/data/models/save_supplier_request.dart';

import 'stages/stage_a_masters.dart';
import 'stages/stage_b_purchase.dart';
import 'stages/stage_c_sales.dart';
import 'stages/stage_d_returns.dart';
import 'stages/stage_e_reports.dart';
import 'stages/stage_fgh.dart';
import 'stages/stage_x_probe.dart';
import 'support/driver.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Caskly Test Run', (t) async {
    final root = await Directory.systemTemp.createTemp('caskly_e2e_');
    DbPaths.rootOverride = root;
    DbPaths.seedDemoDataOverride = false;
    addTearDown(() {
      DbPaths.rootOverride = null;
      DbPaths.seedDemoDataOverride = null;
      try {
        root.deleteSync(recursive: true);
      } catch (_) {}
    });

    await t.pumpWidget(const ProviderScope(child: PosApp()));
    final d = Driver(t);
    d.captureErrors();
    await d.until(() => d.shows('Enter Caskly'), timeout: const Duration(seconds: 30));

    // Background records the checklist doesn't test, and a store that has
    // finished first-run setup (onboarding needs a native file dialog).
    final repo = d.c.read(mastersRepositoryProvider);
    await t.runAsync(() async {
      await d.db.setSetting('onboarding_complete', 'e2e');
      await repo.createSupplier(const SaveSupplierRequest(
          name: 'Magnum Traders', disPercent: 0, openingBalance: 0, balanceType: 'Credit'));
      await repo.createManufacturer(const SaveManufacturerRequest(name: 'UB Group'));
      await repo.createPacking(const SavePackagingRequest(name: '1000 ML', description: 'Litre bottle'));
    });

    // Sign in as the owner; first sign-in must set a new password.
    await d.type('USERNAME', 'owner');
    await d.type('PASSWORD', 'owner123');
    await d.tapText('Enter Caskly');
    await d.until(() => d.shows('Save password'), timeout: const Duration(seconds: 15));
    await d.type('CURRENT PASSWORD', 'owner123');
    await d.type('NEW PASSWORD', 'Owner@2026x');
    await d.type('CONFIRM NEW PASSWORD', 'Owner@2026x');
    await d.tapText('Save password');
    await d.until(() => find.byType(MaterialApp).evaluate().isNotEmpty && !d.shows('Save password'),
        timeout: const Duration(seconds: 15));
    await d.wait(const Duration(seconds: 2));

    // --dart-define=E2E_STAGES=ABC runs only those (A and B set up data later stages use).
    const only = String.fromEnvironment('E2E_STAGES', defaultValue: 'ABCDEFGHZ');
    final stages = {
      'A': stageA, 'B': stageB, 'C': stageC, 'D': stageD, 'E': stageE,
      'F': stageF, 'G': stageG, 'H': stageH, 'Z': stageNoPermit, 'X': stageX,
    };
    for (final e in stages.entries) {
      if (only.contains(e.key)) await e.value(d);
    }

    d.restoreErrors();
    await d.writeReport('build/e2e_report.json');
    final failed = d.results.where((r) => r.status == 'fail').map((r) => r.id).toList();
    // ignore: avoid_print
    print('E2E: ${d.results.where((r) => r.status == 'pass').length} pass, ${failed.length} fail $failed');
  }, timeout: const Timeout(Duration(minutes: 30)));
}
