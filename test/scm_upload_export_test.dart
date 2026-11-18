// SCM daily sale export must match the state portal's upload sheet exactly
// (client sample SCMSample.xlsx, 14 Nov 2026).
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:excel_community/excel_community.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/features/reports/data/scm_upload_exporter.dart';

import 'support/test_env.dart';

void main() {
  test('layout matches the SCM sample: header row 1, every item, blanks for unsold', () async {
    final env = await TestEnv.create(fileBacked: false);
    addTearDown(env.dispose);
    Future<void> item(String code, String name, String category, String size) async {
      await env.addMaterial(code, stock: 50);
      await (env.db.update(env.db.cachedMaterials)..where((t) => t.id.equals(code))).write(CachedMaterialsCompanion(
          name: Value(name), category: Value(category), packing: Value(size), barcode: Value('BC-$code')));
    }

    await item('SCMBR0018627', 'Kingfisher Strong Premium Beer .', 'Strong Beer', '650 ML');
    await item('SCMBR0018626', 'Kingfisher Strong Premium Beer .', 'Strong Beer', '330 ML (CAN)');
    await item('SCMBR0018138', 'Budweiser Magnum Strong Beer .', 'Strong Beer', '500 ML (CAN)');
    await item('SODA-1', 'Club Soda', 'Soft Drink', '750 ML'); // not an SCM item
    await env.sales.createSale(TestEnv.sale({'SCMBR0018627': 5}));

    final today = DateTime.now();
    final bytes = await ScmUploadExporter.build(env.db, today, today);
    final book = Excel.decodeBytes(Uint8List.fromList(bytes));
    expect(book.tables.keys, ['Sheet1']);
    final rows = book.tables['Sheet1']!.rows
        .map((r) => r.map((c) => c?.value?.toString() ?? '').toList())
        .toList();

    expect(rows.first,
        ['Sale Date', 'Local Item Code', 'Brand Name', 'Size', 'Quantity(Case)', 'Quantity(Loose Bottle)']);
    final date = '${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}/${today.year}';
    expect(rows.skip(1).toList(), [
      [date, 'SCMBR0018138', 'Budweiser Magnum Strong Beer .', '500 ML (CAN)', '', ''],
      [date, 'SCMBR0018626', 'Kingfisher Strong Premium Beer .', '330 ML (CAN)', '', ''],
      [date, 'SCMBR0018627', 'Kingfisher Strong Premium Beer .', '650 ML', '', '5'],
    ], reason: 'all liquor items A→Z, no title/total rows, soft drinks excluded');
  });

  test('a date range repeats the item list for each day', () async {
    final env = await TestEnv.create(fileBacked: false);
    addTearDown(env.dispose);
    await env.addMaterial('SCM1');
    final d = DateTime(2026, 11, 14);
    final rows = await ScmUploadExporter.rows(env.db, d, DateTime(2026, 11, 16));
    expect(rows.map((r) => r.first), ['11/14/2026', '11/15/2026', '11/16/2026']);
  });
}
