import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/shared/widgets/inputs/app_text_field.dart';
import 'package:pos_app/features/masters/presentation/license_holder_browser_controller.dart';
import 'package:pos_app/core/local/app_database.dart';

import '../support/driver.dart';

Future<CachedMaterial?> _material(Driver d, String id) => d.t
    .runAsync<CachedMaterial?>(() => (d.db.select(d.db.cachedMaterials)..where((t) => t.id.equals(id))).getSingleOrNull());

Future<List<CachedMaterial>> _materials(Driver d) async =>
    (await d.t.runAsync(() => d.db.select(d.db.cachedMaterials).get()))!;

/// Fills the material form from "New" and presses Create. Returns the
/// SnackBar text shown afterwards.
Future<String> createMaterial(
  Driver d, {
  required String scm,
  String barcode = '',
  required String name,
  required String category,
  String type = '',
  required String packing,
  String counterBrand = '',
  String rate = '100',
  String distributor = '',
}) async {
  await d.go('/material');
  if (d.shows('New')) await d.tapText('New');
  await d.type('SCM CODE *', scm);
  if (barcode.isNotEmpty) await d.type('BARCODE', barcode);
  await d.type('BRAND DISPLAY NAME *', name);
  await d.pick('LIQUOR CATEGORY', category);
  if (type.isNotEmpty) await d.pick('TYPE *', type);
  await d.pick('PACKAGING', packing);
  await d.pick('MANUFACTURER', 'UB Group');
  if (distributor.isNotEmpty) await d.pick('DEFAULT DISTRIBUTOR', distributor);
  if (counterBrand.isNotEmpty) await d.type('COUNTER BRAND NAME', counterBrand);
  await d.type('SALE RATE (₹)', rate);
  await d.type('VAT %', '0');
  await d.tapText('Create');
  await d.wait(const Duration(milliseconds: 800));
  return d.snacks();
}

String _trace(Driver d, String at) {
  final b = d.c.read(licenseHolderBrowserProvider);
  final hasBox = find.byWidgetPredicate((w) => w is AppTextField && w.label == 'Permit Number *').evaluate().isNotEmpty;
  final box = hasBox ? d.textOf(d.field('Permit Number *')) : '-';
  return '$at:idx=${b.index},new=${b.isNew},edit=${b.isEditing},n=${b.licenseHolders.length},box="$box"';
}

Future<void> createHolder(Driver d,
    {String permit = '', required String name, String validity = 'Lifetime', String category = 'License Holder'}) async {
  final trace = <String>[];
  await d.go('/license-holder');
  trace.add(_trace(d, 'go'));
  if (d.shows('New Permit')) {
    await d.tapText('New Permit');
  } else if (d.shows('New')) {
    await d.tapText('New');
  }
  trace.add(_trace(d, 'new'));
  await d.pick('Category', category);
  await d.pick('Validity', validity);
  trace.add(_trace(d, 'picks'));
  if (permit.isNotEmpty) await d.type('Permit Number *', permit);
  trace.add(_trace(d, 'permit'));
  await d.type(category == 'Frequent Buyer' ? 'Name *' : 'Permit Holder Name *', name);
  trace.add(_trace(d, 'name'));
  holderTrace = trace.join(' | ');
  final typedPermit = permit.isEmpty ? '' : d.textOf(d.field('Permit Number *'));
  holderTrace = trace.join(' | ');
  await d.tapText('Create');
  await d.wait(const Duration(milliseconds: 800));
  holderMessage = '${d.snacks()} [permit box before Create: "$typedPermit"]';
}

String holderMessage = '';
String holderTrace = '';

Future<void> stageA(Driver d) async {
  await d.step('a1', 'Shop prefix', () async {
    await d.go('/material');
    await d.tapText('PREFIX ');
    await d.type('PREFIX', 'RS');
    await d.tapText('Save');
    await d.wait(const Duration(milliseconds: 600));
    return d.shows('RS') ? null : 'Prefix chip did not show RS after saving.';
  });

  await d.step('a2', 'Create SCM1/111 Strong beer', () async {
    final snack = await createMaterial(d,
        scm: 'SCM1', barcode: '111', name: 'KF STRONG 650', category: 'Beer', type: 'Strong', packing: '650 ML',
        counterBrand: 'Kingfisher Strong', distributor: 'Magnum Traders');
    final m = await _material(d, 'SCM1');
    if (m == null) return 'Not saved. Screen said: $snack';
    if (m.liquorType != 'Strong' || !m.counterBrandId.startsWith('RS-')) {
      return 'Saved with type "${m.liquorType}", counter brand id "${m.counterBrandId}".';
    }
    return null;
  });

  await d.step('a3', 'Same SCM, barcode 222', () async {
    final snack = await createMaterial(d,
        scm: 'SCM1', barcode: '222', name: 'KF STRONG 650', category: 'Beer', type: 'Strong', packing: '650 ML',
        counterBrand: 'Kingfisher Strong');
    return await _material(d, 'SCM1/222') == null ? 'Second barcode not saved. Screen said: $snack' : null;
  });

  await d.step('a4', 'Duplicate SCM1/111 refused', () async {
    final before = (await _materials(d)).length;
    final snack = await createMaterial(d,
        scm: 'SCM1', barcode: '111', name: 'DUP', category: 'Beer', type: 'Strong', packing: '650 ML');
    final after = (await _materials(d)).length;
    if (after != before) return 'A duplicate was saved.';
    return snack.contains('already exists') ? null : 'No "already exists" message. Screen said: "$snack"';
  });

  await d.step('a5', 'Edit barcode into an existing pair refused', () async {
    await d.go('/material');
    // Pick the SCM1 row whose barcode is 222 (shown under the SCM code).
    await d.tapText('222');
    await d.tapText('Edit');
    await d.type('BARCODE', '111');
    await d.tapText('Save');
    await d.wait(const Duration(milliseconds: 800));
    final snack = d.snacks();
    final m = await _material(d, 'SCM1/222');
    if (m?.barcode != '222') return 'Barcode was changed to ${m?.barcode}.';
    if (d.shows('Cancel')) await d.tapText('Cancel');
    return snack.contains('already exists') ? null : 'Not refused with a message. Screen said: "$snack"';
  });

  await d.step('a6', 'Beer without a type refused', () async {
    final snack = await createMaterial(d, scm: 'SCMNT', barcode: '777', name: 'NO TYPE BEER', category: 'Beer', packing: '650 ML');
    if (await _material(d, 'SCMNT') != null) return 'Beer saved without a type.';
    return snack.isEmpty ? 'Refused but no message shown.' : null;
  });

  await d.step('a7', 'Wine in 1000 ML', () async {
    final snack = await createMaterial(d, scm: 'SCMW', barcode: '333', name: 'BIG RED WINE', category: 'Wine', packing: '1000 ML');
    return await _material(d, 'SCMW') == null ? 'Not saved. Screen said: $snack' : null;
  });

  await d.step('a8', 'Two items on barcode 999', () async {
    await createMaterial(d, scm: 'SCM2', barcode: '999', name: 'TUBORG STRONG A', category: 'Beer', type: 'Strong', packing: '650 ML');
    await createMaterial(d, scm: 'SCM3', barcode: '999', name: 'TUBORG STRONG B', category: 'Beer', type: 'Strong', packing: '650 ML');
    final both = (await _materials(d)).where((m) => m.barcode == '999').length;
    return both == 2 ? null : 'Expected 2 items on 999, found $both.';
  });

  await d.step('a9', 'Counter brand names differing by case share one ID', () async {
    await createMaterial(d,
        scm: 'SCM4', barcode: '444', name: 'KF STRONG 500 CAN', category: 'Beer', type: 'Strong',
        packing: '500 ML (CAN)', counterBrand: 'kingfisher strong');
    final a = await _material(d, 'SCM1'), b = await _material(d, 'SCM4');
    if (b == null) return 'Second item not saved.';
    return a!.counterBrandId == b.counterBrandId
        ? null
        : 'IDs differ: ${a.counterBrandId} vs ${b.counterBrandId} ("${a.counterBrandName}" / "${b.counterBrandName}").';
  });

  await d.step('a10', 'Default distributor saved', () async {
    final m = await _material(d, 'SCM1');
    return (m?.defaultSupplierId ?? '').isNotEmpty ? null : 'SCM1 has no default distributor.';
  });

  await d.step('a11', 'License holders: 2 Lifetime, 1 One Time, 1 Frequent Buyer', () async {
    await createHolder(d, permit: 'LT-1', name: 'RAMESH PATIL');
    await createHolder(d, permit: 'LT-2', name: 'SURESH JADHAV');
    await createHolder(d, permit: 'OT-1', name: 'ONE TIME OMKAR', validity: 'One Time');
    await createHolder(d, name: 'REGULAR RAJU', category: 'Frequent Buyer');
    final all = (await d.t.runAsync(() => d.db.select(d.db.cachedLicenseHolders).get()))!;
    final names = all.map((h) => h.name).toSet();
    final missing = ['RAMESH PATIL', 'SURESH JADHAV', 'ONE TIME OMKAR', 'REGULAR RAJU'].where((n) => !names.contains(n));
    if (missing.isNotEmpty) return 'Not saved: ${missing.join(', ')}.';
    final raju = all.firstWhere((h) => h.name == 'REGULAR RAJU');
    return raju.permitNo.isEmpty && raju.category == 'Frequent Buyer' ? null : 'Frequent buyer saved wrongly.';
  });

  await d.step('a12', 'Edited permit no can be reused without overwriting', () async {
    await d.go('/license-holder');
    await d.search('Search by permit no', 'SURESH');
    await d.tapText('SURESH JADHAV');
    await d.type('Permit Number *', 'LT-2B');
    await d.tapText('Save');
    await d.wait(const Duration(milliseconds: 600));
    await createHolder(d, permit: 'LT-2', name: 'NEW HOLDER NITIN');
    await d.search('Search by permit no', '');
    final all = (await d.t.runAsync(() => d.db.select(d.db.cachedLicenseHolders).get()))!;
    final byName = {for (final h in all) h.name: h.permitNo};
    if (byName['SURESH JADHAV'] != 'LT-2B') return 'Edited holder now has permit ${byName['SURESH JADHAV']}.';
    if (byName['NEW HOLDER NITIN'] != 'LT-2') return 'New holder not saved with LT-2. Screen said: "$holderMessage" TRACE $holderTrace';
    return null;
  });
}
