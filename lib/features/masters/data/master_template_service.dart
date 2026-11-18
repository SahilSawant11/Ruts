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
      'SCM Code', 'Barcode', 'Brand Display Name', 'Liquor Category', 'Type', 'Packaging',
      'Manufacturer', 'Counter Brand Name', 'Sale Rate', 'Wholesale Rate', 'VAT %', 'Discount %',
      'Distributor',
    ],
    MasterImportTarget.suppliers: [
      'Name', 'Address', 'Contact No', 'Email', 'VAT No', 'Bank Details',
      'Discount %', 'Opening Balance', 'Balance Type',
    ],
    MasterImportTarget.licenseHolders: [
      'Permit No', 'Permit Holder Name', 'Issued Date', 'City', 'Validity', 'Address',
      'Contact Number', 'Remark', 'Category',
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
          ['SCM Code', 'Required. The same SCM code may appear on several rows with different barcodes.'],
          ['Barcode', 'Optional. Blank = SCM Code. SCM Code + Barcode together must be new.'],
          ['Brand Display Name', 'Required. Name as on the bottle (e.g. KINGFISHER SUPER STRONG).'],
          ['Liquor Category', 'Required. Beer, Wine, Whisky, Rum… — use one of the categories below.'],
          ['Type', 'Beer only, required for beer: Mild, Strong or Fermented. Decides the brandwise section.'],
          ['Packaging', 'Bottle size, e.g. 750 ML, 650 ML, 500 ML (CAN), 330 ML (CAN).'],
          ['Manufacturer', 'The company, e.g. UB Group. Blank = first word of the name.'],
          ['Counter Brand Name', 'Bottles that look the same share one (e.g. KINGFISHER STRONG). '
              'Brandwise reports add them up under it. Blank = Brand Display Name without a trailing " ." '
              'or (s)/(OS). The ID is made for you.'],
          ['Sale Rate', 'MRP / selling price per bottle, numbers only.'],
          ['Wholesale Rate', 'Optional, numbers only.'],
          ['VAT %', 'Numbers only. Blank = 0.'],
          ['Discount %', 'Applied automatically when billed. Blank = 0.'],
          ['Distributor', 'Optional. Who usually supplies it (e.g. Magnum Traders); pre-fills Purchase. '
              'New names are added to Distributors.'],
          ['', ''],
          ['Categories', categories.isEmpty ? 'Beer, Wine, Whisky, Rum, Vodka, Brandy, Gin' : categories.join(', ')],
          if (packings.isNotEmpty) ['Packings', packings.join(', ')],
          ['Example', 'SCM1234 | 84549000 | KINGFISHER STRONG | Beer | Strong | 650 ML | UB Group | '
              'KINGFISHER STRONG | 190 | 170 | 0 | 0 | Magnum Traders'],
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
          ['Permit No', 'Required for License Holders. Leave blank for Frequent Buyers.'],
          ['Permit Holder Name', 'Required.'],
          ['Issued Date', 'Optional, e.g. 14-Nov-2026.'],
          ['City', 'Optional.'],
          ['Validity', 'One Time or Lifetime. Blank = Lifetime.'],
          ['Address / Contact Number / Remark', 'Optional.'],
          ['Category', 'License Holder or Frequent Buyer. Blank = License Holder.'],
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
