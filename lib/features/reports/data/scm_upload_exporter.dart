import 'dart:io';

import 'package:excel_community/excel_community.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/local/app_database.dart';
import 'brandwise_sections.dart';

/// SCM daily sale export in the exact layout of the state SCM portal's
/// upload sheet (client sample "SCMSample.xlsx"):
///
///   Row 1: Sale Date | Local Item Code | Brand Name | Size |
///          Quantity(Case) | Quantity(Loose Bottle)
///   Then one row per liquor item the shop stocks — sold or not — with the
///   quantity cells left blank when nothing was sold. No title, no totals,
///   .xlsx, sheet "Sheet1". A multi-day range repeats the item list per day.
class ScmUploadExporter {
  static const headers = [
    'Sale Date', 'Local Item Code', 'Brand Name', 'Size', 'Quantity(Case)', 'Quantity(Loose Bottle)',
  ];
  static const _widths = [11.83, 16.37, 45.13, 13.53, 14.82, 21.82];

  /// Rows (without header) for each calendar day from [from] to [to].
  static Future<List<List<Object?>>> rows(AppDatabase db, DateTime from, DateTime to) async {
    final materials = (await db.select(db.cachedMaterials).get())
        .where((m) => m.isActive && brandwiseSection(m.category) != null)
        .toList()
      ..sort((a, b) {
        final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return byName != 0 ? byName : a.id.compareTo(b.id);
      });

    final out = <List<Object?>>[];
    for (var day = DateTime(from.year, from.month, from.day);
        !day.isAfter(DateTime(to.year, to.month, to.day));
        day = DateTime(day.year, day.month, day.day + 1)) {
      final lines = await (db.select(db.cachedSaleLineItems)
            ..where((t) => db.lineOfActiveBillBetween(t, day, DateTime(day.year, day.month, day.day + 1))))
          .get();
      final cases = <String, int>{};
      final loose = <String, int>{};
      for (final l in lines) {
        final id = l.materialId ?? '';
        if (id.isEmpty) continue;
        cases[id] = (cases[id] ?? 0) + l.qtyCase;
        loose[id] = (loose[id] ?? 0) + l.quantity;
      }
      final date = _slashDate(day);
      for (final m in materials) {
        final c = cases[m.id] ?? 0;
        final b = loose[m.id] ?? 0;
        out.add([date, m.id, m.name, m.packing, c == 0 ? null : c, b == 0 ? null : b]);
      }
    }
    return out;
  }

  static Future<List<int>> build(AppDatabase db, DateTime from, DateTime to) async {
    final excel = Excel.createExcel(); // default sheet is "Sheet1", like the sample
    final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[sheetName];
    sheet.appendRow([for (final h in headers) TextCellValue(h)]);
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = CellStyle(bold: true);
      sheet.setColumnWidth(i, _widths[i]);
    }
    for (final r in await rows(db, from, to)) {
      sheet.appendRow([
        for (final v in r)
          switch (v) {
            null => null,
            int n => IntCellValue(n),
            _ => TextCellValue(v.toString()),
          },
      ]);
    }
    return excel.encode()!;
  }

  Future<File> export(AppDatabase db, DateTime from, DateTime to) async {
    final base = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}Caskly Reports');
    await dir.create(recursive: true);
    final a = _stamp(from), b = _stamp(to);
    final file = File('${dir.path}${Platform.pathSeparator}scm_daily_sale_${a == b ? a : '${a}_to_$b'}.xlsx');
    await file.writeAsBytes(await build(db, from, to));
    return file;
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
  static String _slashDate(DateTime d) => '${_two(d.month)}/${_two(d.day)}/${d.year}';
  static String _stamp(DateTime d) => '${d.year}${_two(d.month)}${_two(d.day)}';
}
