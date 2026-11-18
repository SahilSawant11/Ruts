import 'dart:io';

import 'package:excel_community/excel_community.dart';
import 'package:path_provider/path_provider.dart';

import 'master_import_service.dart';

/// Blank Excel templates for onboarding: one workbook per master, whose
/// first sheet has exactly the headers [MasterImportService] reads. A second
/// "How to fill" sheet explains each column — it is never imported.
class MasterTemplateService {
  /// Column headers per master, in sheet order.
  static const headers = <MasterImportTarget, List<String>>{
    MasterImportTarget.materials: [
      'Item Code', 'Name', 'Manufacturer', 'Category', 'Packing', 'Sale Rate', 'GST %', 'Barcode',
    ],
    MasterImportTarget.suppliers: [
      'Name', 'Address', 'Contact No', 'Email', 'VAT No', 'Bank Details',
      'Discount %', 'Opening Balance', 'Balance Type',
    ],
    MasterImportTarget.licenseHolders: [
      'Permit No', 'Permit Holder Name', 'Issued Date', 'Where Granted',
    ],
  };

  static String sheetName(MasterImportTarget t) => switch (t) {
        MasterImportTarget.materials => 'Materials',
        MasterImportTarget.suppliers => 'Distributors',
        MasterImportTarget.licenseHolders => 'Permit Holders',
      };

  /// Builds the workbook bytes. [categories] / [packings] are listed on the
  /// help sheet so the client types names that already exist.
  List<int> build(
    MasterImportTarget target, {
    List<String> categories = const [],
    List<String> packings = const [],
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    final dataSheet = sheetName(target);
    excel.rename(defaultSheet, dataSheet);

    final cols = headers[target]!;
    excel.appendRow(dataSheet, [for (final h in cols) TextCellValue(h)]);
    final sheet = excel[dataSheet];
    for (var i = 0; i < cols.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle =
          CellStyle(bold: true);
      sheet.setColumnWidth(i, i == 1 ? 32 : 18);
    }

    const help = 'How to fill';
    for (final row in _helpRows(target, categories, packings)) {
      excel.appendRow(help, [for (final v in row) TextCellValue(v)]);
    }
    excel[help].setColumnWidth(0, 22);
    excel[help].setColumnWidth(1, 70);
    excel.setDefaultSheet(dataSheet);

    return excel.encode()!;
  }

  /// Saves the template to Downloads/Caskly Templates and returns the file.
  Future<File> save(
    MasterImportTarget target, {
    List<String> categories = const [],
    List<String> packings = const [],
  }) async {
    final base = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}Caskly Templates');
    await dir.create(recursive: true);
    final name = 'caskly_${sheetName(target).toLowerCase().replaceAll(' ', '_')}_template.xlsx';
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(build(target, categories: categories, packings: packings));
    return file;
  }

  List<List<String>> _helpRows(
    MasterImportTarget target,
    List<String> categories,
    List<String> packings,
  ) {
    final rows = <List<String>>[
      ['Column', 'What to enter'],
    ];
    switch (target) {
      case MasterImportTarget.materials:
        rows.addAll([
          ['Item Code', 'Required. SCM / item code, unique per brand + size (e.g. KFSTRONG-650).'],
          ['Name', 'Required. Brand name as on the brandwise register (e.g. KINGFISHER STRONG).'],
          ['Manufacturer', 'Company (e.g. United Breweries). Blank = first word of the name.'],
          ['Category', 'Required. Decides the brandwise section — use one of the categories below.'],
          ['Packing', 'Bottle size, e.g. 750 ML, 650 ML, 500 ML (CAN), 330 ML (CAN).'],
          ['Sale Rate', 'MRP / selling price per bottle, numbers only.'],
          ['GST %', 'Tax percent, numbers only. Blank = 0.'],
          ['Barcode', 'Optional. Blank = Item Code.'],
          ['', ''],
          ['Categories', categories.isEmpty ? 'Fermented Beer, Strong Beer, Mild Beer, Wine' : categories.join(', ')],
          if (packings.isNotEmpty) ['Packings', packings.join(', ')],
          ['Example', 'KFSTRONG-650 | KINGFISHER STRONG | United Breweries | Strong Beer | 650 ML | 190 | 0'],
        ]);
      case MasterImportTarget.suppliers:
        rows.addAll([
          ['Name', 'Required. Distributor name.'],
          ['Address / Contact No / Email', 'Optional.'],
          ['VAT No', 'VAT / GSTIN number, optional.'],
          ['Bank Details', 'Optional.'],
          ['Discount %', 'Default discount percent, numbers only.'],
          ['Opening Balance', 'Amount owed at start, numbers only.'],
          ['Balance Type', 'Credit or Debit. Blank = Credit.'],
        ]);
      case MasterImportTarget.licenseHolders:
        rows.addAll([
          ['Permit No', 'Required. Permit / licence number.'],
          ['Permit Holder Name', 'Required.'],
          ['Issued Date', 'Optional, e.g. 14-11-2026.'],
          ['Where Granted', 'Optional, e.g. One day / Yearly / Lifetime.'],
        ]);
    }
    rows.addAll([
      ['', ''],
      ['Import', 'Fill the first sheet only (one row per entry), save, then Masters → Import Excel. '
          'Rows whose code / name already exists are skipped.'],
    ]);
    return rows;
  }
}
