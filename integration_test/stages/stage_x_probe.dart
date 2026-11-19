import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/features/masters/presentation/material_browser_controller.dart';

import '../support/driver.dart';

String _form(Driver d) {
  final b = d.c.read(materialBrowserProvider);
  String box(String l) => find.byWidgetPredicate((w) => w.runtimeType.toString() == 'AppTextField' && (w as dynamic).label == l).evaluate().isEmpty
      ? '-'
      : d.textOf(d.field(l));
  return 'idx=${b.index} new=${b.isNew} edit=${b.isEditing} scm="${box('SCM CODE *')}" bc="${box('BARCODE')}" name="${box('BRAND DISPLAY NAME *')}"';
}

Future<void> stageX(Driver d) async {
  await d.step('x1', 'New after selecting another item creates a clean record', () async {
    final trace = <String>[];
    await d.go('/material');
    await d.search('Search name, SCM code', 'SCM4');
    await d.tapText('SCM4', last: true);
    await d.search('Search name, SCM code', '');
    trace.add('selected: ${_form(d)}');
    await d.tapText('New');
    trace.add('new: ${_form(d)}');
    await d.type('SCM CODE *', 'SCMX1');
    trace.add('scm: ${_form(d)}');
    await d.type('BARCODE', '8181');
    await d.type('BRAND DISPLAY NAME *', 'PROBE BEER');
    trace.add('name: ${_form(d)}');
    await d.pick('LIQUOR CATEGORY', 'Beer');
    trace.add('cat: ${_form(d)}');
    await d.pick('TYPE *', 'Mild');
    await d.pick('PACKAGING', '650 ML');
    trace.add('pack: ${_form(d)}');
    await d.pick('MANUFACTURER', 'UB Group');
    await d.type('SALE RATE (₹)', '120');
    trace.add('rate: ${_form(d)}');
    await d.snapshot('x1_before_create');
    await d.tapText('Create');
    await d.wait(const Duration(milliseconds: 800));
    final m = await d.t.runAsync<CachedMaterial?>(
        () => (d.db.select(d.db.cachedMaterials)..where((t) => t.id.equals('SCMX1'))).getSingleOrNull());
    final got = m == null ? 'not saved' : '${m.barcode}/${m.name}/${m.packing}/${m.liquorType}';
    return got == '8181/PROBE BEER/650 ML/Mild' ? null : 'Saved $got. TRACE ${trace.join(' | ')}';
  });
}
