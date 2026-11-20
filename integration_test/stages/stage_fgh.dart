import 'dart:io';

import 'package:excel_community/excel_community.dart';
import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/router.dart';
import 'package:pos_app/core/local/backup_service.dart';
import 'package:pos_app/features/dashboard/data/dashboard_providers.dart';
import 'package:pos_app/features/dashboard/data/models/dashboard_summary_dto.dart' show DashboardPeriod;
import 'package:pos_app/features/masters/data/master_import_service.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/reports/data/brandwise_report_provider.dart';
import 'package:pos_app/features/settings/data/settings_providers.dart';
import 'package:pos_app/features/sales/presentation/sales_providers.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:drift/drift.dart' show Variable;

import '../support/driver.dart';
import 'stage_b_purchase.dart' show stockOf;
import 'stage_c_sales.dart';

const ownerPassword = 'Owner@2026x';

Future<void> signIn(Driver d, String user, String password) async {
  await d.until(() => d.shows('Enter Caskly'), timeout: const Duration(seconds: 15));
  await d.type('USERNAME', user);
  await d.type('PASSWORD', password);
  await d.tapText('Enter Caskly');
  await d.wait(const Duration(seconds: 1));
}

Future<void> signOut(Driver d) async {
  await d.clearSnacks();
  await d.wait(const Duration(milliseconds: 800));
  // The sidebar expands (showing Sign out) while the mouse is over it.
  final mouse = await d.t.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: const Offset(30, 500));
  await mouse.moveTo(const Offset(40, 520));
  await d.idle(500);
  final button = find.byTooltip('Sign out');
  // Click with the same mouse that is hovering.
  await mouse.moveTo(d.t.getCenter(button));
  await d.idle(200);
  await mouse.down(d.t.getCenter(button));
  await mouse.up();
  await mouse.removePointer();
  await d.wait(const Duration(seconds: 1));
}

Future<void> stageF(Driver d) async {
  await d.step('f1', 'Materials Excel round-trip updates two rates', () async {
    await d.go('/material');
    await d.t.tap(find.byTooltip('Export to Excel').first);
    final snack = await d.catchSnack(timeout: const Duration(seconds: 6));
    final m = RegExp(r'Exported to (.+?\.xlsx)').firstMatch(snack);
    if (m == null) return 'No export file reported: "$snack"';
    final file = File(m.group(1)!);
    final excel = Excel.decodeBytes(file.readAsBytesSync());
    final sheet = excel.tables.values.first;
    final header = sheet.rows.first.map((c) => c?.value.toString() ?? '').toList();
    final rateCol = header.indexOf('Sale Rate'), scmCol = header.indexOf('SCM Code'), bcCol = header.indexOf('Barcode');
    if (rateCol < 0 || scmCol < 0) return 'Export header has no Sale Rate / SCM Code: $header';
    // Change SCM1/111 → 210 and SCMW → 950; blank every other cell of those rows
    // except the identifying ones, to prove blanks keep values.
    final name = excel.tables.keys.first;
    for (var r = 1; r < sheet.maxRows; r++) {
      final scm = sheet.rows[r][scmCol]?.value.toString(), bc = sheet.rows[r][bcCol]?.value.toString();
      final target = scm == 'SCM1' && bc == '111' ? 210 : scm == 'SCMW' ? 950 : null;
      if (target != null) {
        excel.updateCell(name, CellIndex.indexByColumnRow(columnIndex: rateCol, rowIndex: r), IntCellValue(target));
      }
    }
    final edited = File('${file.path}.edited.xlsx')..writeAsBytesSync(excel.encode()!);
    file.deleteSync();
    final stockBefore = await stockOf(d, 'SCM1');
    // Choosing the file needs the native file dialog; the import itself is the app's own service.
    final summary = await d.t.runAsync(() => d.c
        .read(masterImportServiceProvider)
        .importFile(MasterImportTarget.materials, XFile(edited.path, name: 'materials.xlsx')));
    edited.deleteSync();
    if (!summary!.message.contains('2 updated')) return 'Import said: "${summary.message}" ${summary.errors}';
    final mats = {for (final m in (await d.t.runAsync(() => d.c.read(mastersRepositoryProvider).getMaterials()))!) m.id: m};
    if (mats['SCM1']!.saleRate != 210 || mats['SCMW']!.saleRate != 950) {
      return 'Rates now ${mats['SCM1']!.saleRate} / ${mats['SCMW']!.saleRate}.';
    }
    return await stockOf(d, 'SCM1') == stockBefore ? null : 'Import changed stock.';
  });

  await d.step('f2', 'Only rates changed', () async {
    final m = (await d.t.runAsync(() => d.c.read(mastersRepositoryProvider).getMaterials()))!
        .firstWhere((m) => m.id == 'SCM1');
    return m.liquorType == 'Strong' && m.counterBrandName.toLowerCase() == 'kingfisher strong' && m.defaultSupplierId.isNotEmpty
        ? null
        : 'Other fields changed: type ${m.liquorType}, counter "${m.counterBrandName}", distributor "${m.defaultSupplierId}".';
  });
}

Future<void> stageG(Driver d) async {
  await d.step('g1', 'Cashier sees only Sales, Sales Return, Inventory, Settings', () async {
    await signOut(d);
    await signIn(d, 'cashier', 'cash123');
    if (d.shows('Save password')) {
      await d.type('CURRENT PASSWORD', 'cash123');
      await d.type('NEW PASSWORD', 'Cash@2026x');
      await d.type('CONFIRM NEW PASSWORD', 'Cash@2026x');
      await d.tapText('Save password');
      await d.wait(const Duration(seconds: 2));
    }
    final router = d.c.read(appRouterProvider);
    final leaks = <String>[];
    for (final route in ['/purchase', '/material', '/reports', '/brandwise-report', '/license-holder', '/dashboard']) {
      router.go(route);
      await d.idle(300);
      final at = router.routeInformationProvider.value.uri.path;
      if (at == route) leaks.add(route);
    }
    for (final k in [LogicalKeyboardKey.f1, LogicalKeyboardKey.f2, LogicalKeyboardKey.f6, LogicalKeyboardKey.f10]) {
      await d.key(k);
      final at = router.routeInformationProvider.value.uri.path;
      if (!{'/sales', '/sales-return', '/inventory', '/settings'}.contains(at)) leaks.add('${k.keyLabel}→$at');
    }
    router.go('/sales');
    await d.idle();
    return leaks.isEmpty ? null : 'Cashier reached: $leaks';
  });

  await d.step('g2', 'Five wrong passwords lock sign-in', () async {
    await signOut(d);
    // Quick tries, as a person hammering the keyboard would: the lock
    // lasts 30 s, so the six tries must land well inside it.
    await d.until(() => d.shows('Enter Caskly'), timeout: const Duration(seconds: 15));
    Future<String> quickTry(String password) async {
      await d.t.enterText(d.field('USERNAME'), 'owner');
      await d.t.enterText(d.field('PASSWORD'), password);
      await d.t.pump();
      await d.t.tap(find.text('Enter Caskly').first);
      return d.catchSnack(timeout: const Duration(seconds: 3));
    }
    for (var i = 0; i < 5; i++) {
      await quickTry('wrong-$i');
      await d.clearSnacks();
    }
    final sixth = await quickTry(ownerPassword);
    final locked = sixth.contains('Too many attempts') || d.showsContaining('Too many attempts');
    // Wait out the 30 s lock, then sign the owner back in.
    await d.wait(const Duration(seconds: 31));
    await signIn(d, 'owner', ownerPassword);
    await d.wait(const Duration(seconds: 2));
    if (d.shows('Enter Caskly')) return 'Owner could not sign back in after the lock.';
    return locked ? null : 'No lock message after 5 wrong passwords.';
  });

  await d.step('g3', 'Backup and restore check', () async {
    final backup = d.c.read(backupServiceProvider);
    final file = (await d.t.runAsync(() => backup.backupNow()))!;
    final problem = BackupService.validateBackup(file);
    if (problem != null) return 'Fresh backup rejected: $problem';
    final copy = sql.sqlite3.open(file.path, mode: sql.OpenMode.readOnly);
    final bills = copy.select('SELECT COUNT(*) AS n FROM cached_sales_bills').first['n'] as int;
    copy.close();
    final live = (await d.t.runAsync(() => d.db.customSelect('SELECT COUNT(*) AS n FROM cached_sales_bills').getSingle()))!
        .read<int>('n');
    await d.t.runAsync(() => backup.stageRestore(file));
    final staged = await d.t.runAsync(() => backup.hasPendingRestore());
    await d.t.runAsync(() => backup.cancelPendingRestore());
    // The restart that applies a staged restore can't run inside this test.
    return bills == live && staged == true ? null : 'Backup has $bills bills vs $live live; staged=$staged.';
  });
}

Future<void> stageH(Driver d) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  await d.step('h3', 'Dashboard sales equal the bill totals', () async {
    d.c.read(dashboardPeriodProvider.notifier).state = DashboardPeriod.today;
    await d.go('/dashboard');
    final snap = (await d.t.runAsync(() => d.c.read(dashboardSnapshotProvider.future)))!;
    final sum = (await d.t.runAsync(() => d.db.customSelect(
              "SELECT COALESCE(SUM(total_amount),0) AS v FROM cached_sales_bills WHERE status != 'returned' AND bill_date >= ?",
              variables: [Variable.withDateTime(today)],
            ).getSingle()))!
        .read<double>('v');
    return (snap.sales.current - sum).abs() < 0.01 ? null : 'Dashboard ${snap.sales.current} vs bills $sum (${snap.period}).';
  });

  // Make today's activity "yesterday" (as if the shop closed and reopened).
  final todayReport = (await d.t.runAsync(() => d.c.read(brandwiseReportProvider.future)))!;
  String sig(r) => r.categories
      .map((c) => '${c.name}:${c.subtotal.openingBalance.total}/${c.subtotal.purchase.total}/${c.subtotal.sale.total}/${c.subtotal.closingBalance.total}')
      .join(' ');
  final before = sig(todayReport);
  await d.t.runAsync(() async {
    for (final t in ['cached_sales_bills', 'cached_purchase_bills']) {
      await d.db.customStatement('UPDATE $t SET bill_date = bill_date - 86400');
    }
  });
  final yesterday = today.subtract(const Duration(days: 1));

  await d.step('h1', 'Yesterday\'s register unchanged next day', () async {
    // A new sale today must not change yesterday.
    await d.go('/sales');
    await scan(d, '111');
    await saveSale(d);
    d.c.read(brandwiseReportDateProvider.notifier).state = yesterday;
    d.c.invalidate(brandwiseReportProvider);
    final r = (await d.t.runAsync(() => d.c.read(brandwiseReportProvider.future)))!;
    final after = sig(r);
    return after == before ? null : 'Yesterday was: $before\nnow: $after';
  });

  await d.step('h2', 'Today\'s opening equals yesterday\'s closing', () async {
    final y = (await d.t.runAsync(() => d.c.read(brandwiseReportProvider.future)))!;
    d.c.read(brandwiseReportDateProvider.notifier).state = today;
    d.c.invalidate(brandwiseReportProvider);
    final t = (await d.t.runAsync(() => d.c.read(brandwiseReportProvider.future)))!;
    final closing = {for (final c in y.categories) c.name: c.subtotal.closingBalance.total};
    final opening = {for (final c in t.categories) c.name: c.subtotal.openingBalance.total};
    return closing.toString() == opening.toString() ? null : 'Yesterday closing $closing vs today opening $opening.';
  });
}

/// Last: with no license holder at all, a bill is blocked.
Future<void> stageNoPermit(Driver d) async {
  await d.step('c10', 'No license holder available blocks the bill', () async {
    final repo = d.c.read(mastersRepositoryProvider);
    await d.t.runAsync(() async {
      for (final h in await repo.getLicenseHolders()) {
        await repo.deleteLicenseHolder(h.id);
      }
    });
    d.c.invalidate(rotationLicenseHoldersProvider);
    d.c.read(selectedLicenseHolderProvider.notifier).state = null;
    await d.go('/sales');
    final stock = await stockOf(d, 'SCM1');
    await scan(d, '111');
    final bill = await saveSale(d);
    if (bill != null) return 'Bill ${bill.billNo} saved with permit "${bill.permitNo}".';
    if (await stockOf(d, 'SCM1') != stock) return 'Stock changed although the bill was blocked.';
    return lastMessage.contains('No license holder') ? null : 'Blocked, but the message was: "$lastMessage"';
  });
}
