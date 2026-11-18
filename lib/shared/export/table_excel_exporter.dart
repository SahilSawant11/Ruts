import 'dart:io';

import 'package:excel_community/excel_community.dart';
import 'package:path_provider/path_provider.dart';

/// Writes a simple one-sheet table (bold header row + data rows) as .xlsx
/// into Downloads/Caskly Exports. Numbers stay numeric so Excel can sum them.
class TableExcelExporter {
  const TableExcelExporter();

  List<int> build({
    required String sheetName,
    required List<String> headers,
    required List<List<Object?>> rows,
  }) {
    final excel = Excel.createExcel();
    excel.rename(excel.getDefaultSheet() ?? 'Sheet1', sheetName);
    final sheet = excel[sheetName];
    sheet.appendRow([for (final h in headers) TextCellValue(h)]);
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = CellStyle(bold: true);
      sheet.setColumnWidth(i, headers[i].length > 14 ? headers[i].length + 6.0 : 18);
    }
    for (final row in rows) {
      sheet.appendRow([for (final v in row) _cell(v)]);
    }
    return excel.encode()!;
  }

  Future<File> save({
    required String fileBaseName,
    required String sheetName,
    required List<String> headers,
    required List<List<Object?>> rows,
  }) async {
    final base = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}Caskly Exports');
    await dir.create(recursive: true);
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
    final file = File('${dir.path}${Platform.pathSeparator}${fileBaseName}_$stamp.xlsx');
    await file.writeAsBytes(build(sheetName: sheetName, headers: headers, rows: rows));
    return file;
  }

  static CellValue? _cell(Object? v) => switch (v) {
        null => null,
        int i => IntCellValue(i),
        double d => DoubleCellValue(d),
        bool b => BoolCellValue(b),
        DateTime d => TextCellValue(
            '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year} '
            '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'),
        _ => TextCellValue(v.toString()),
      };
}
