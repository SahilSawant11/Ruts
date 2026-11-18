import 'dart:convert';

import 'package:excel_community/excel_community.dart';
import 'package:file_selector/file_selector.dart';
import 'package:xml/xml.dart';

import '../../../core/network/api_exception.dart';
import 'local_masters_repository.dart';
import 'liquor_type.dart';
import 'models/license_holder_dto.dart';
import 'models/save_material_request.dart';
import 'models/save_supplier_request.dart';
import 'models/save_license_holder_request.dart';

enum MasterImportTarget { materials, suppliers, licenseHolders }

class MasterImportSummary {
  const MasterImportSummary({
    required this.target,
    required this.fileName,
    required this.imported,
    required this.skipped,
    required this.failed,
    required this.errors,
  });

  final MasterImportTarget target;
  final String fileName;
  final int imported;
  final int skipped;
  final int failed;
  final List<String> errors;

  String get entityLabel => switch (target) {
        MasterImportTarget.materials => 'materials',
        MasterImportTarget.suppliers => 'suppliers',
        MasterImportTarget.licenseHolders => 'license holders',
      };

  String get message {
    final parts = <String>[
      '$imported $entityLabel imported',
      '$skipped skipped',
    ];
    if (failed > 0) {
      parts.add('$failed failed');
    }
    return '${parts.join(' · ')} from $fileName';
  }
}

class MasterImportService {
  MasterImportService(this._repo);

  final LocalMastersRepository _repo;

  Future<MasterImportSummary?> pickAndImport(MasterImportTarget target) async {
    const typeGroup = XTypeGroup(
      label: 'Excel or CSV',
      extensions: ['xlsx', 'xls', 'csv'],
    );
    final file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[typeGroup],
      confirmButtonText: 'Import',
    );
    if (file == null) return null;
    return importFile(target, file);
  }

  Future<MasterImportSummary> importFile(MasterImportTarget target, XFile file) async {
    final rows = await readRows(file);
    if (rows.length < 2) {
      throw const ApiException('The selected file does not contain any data rows.');
    }

    final headerMap = _buildHeaderMap(rows.first);
    return switch (target) {
      MasterImportTarget.materials => _importMaterials(file.name, rows.skip(1).toList(), headerMap),
      MasterImportTarget.suppliers => _importSuppliers(file.name, rows.skip(1).toList(), headerMap),
      MasterImportTarget.licenseHolders => _importLicenseHolders(file.name, rows.skip(1).toList(), headerMap),
    };
  }

  Future<MasterImportSummary> _importLicenseHolders(
    String fileName,
    List<List<String>> rows,
    Map<String, int> headerMap,
  ) async {
    final permitIndex = _requiredIndex(headerMap, const [
      'permitno',
      'permitnumber',
      'licenseno',
      'licensenumber',
      'permit',
      'no',
      'id'
    ]);
    final nameIndex = _requiredIndex(headerMap, const [
      'permitholdername',
      'permitholder',
      'licenseholdername',
      'licenseholder',
      'holdername',
      'name'
    ]);
    final dateIndex = _findIndex(headerMap, const ['issueddate', 'dateissued', 'date', 'issued', 'issue_date', 'issued_date']);
    final validityIndex = _findIndex(headerMap, const ['validity', 'type']);
    // Older sheets put the validity ("Life Time") under Where Granted.
    final whereIndex = _findIndex(headerMap, const ['wheregranted', 'granted', 'where', 'where_granted']);
    final cityIndex = _findIndex(headerMap, const ['city', 'place']);
    final addressIndex = _findIndex(headerMap, const ['address']);
    final contactIndex = _findIndex(headerMap, const ['contactnumber', 'contactno', 'contact', 'mobile', 'phone']);
    final remarkIndex = _findIndex(headerMap, const ['remark', 'remarks', 'note', 'notes']);
    final categoryIndex = _findIndex(headerMap, const ['category']);

    var imported = 0;
    var skipped = 0;
    var failed = 0;
    final errors = <String>[];
    final toUpsert = <SaveLicenseHolderRequest>[];

    for (var rowNumber = 0; rowNumber < rows.length; rowNumber++) {
      final row = rows[rowNumber];
      if (_rowIsBlank(row)) continue;

      final permitNo = _valueAt(row, permitIndex);
      final name = _valueAt(row, nameIndex);

      final isBuyer = _valueAt(row, categoryIndex).toLowerCase().contains('frequent');
      if (name.isEmpty || (permitNo.isEmpty && !isBuyer)) {
        skipped++;
        continue;
      }

      final issuedDate = _nullable(_valueAt(row, dateIndex));
      final whereGranted = _nullable(_valueAt(row, whereIndex));
      final validityText = '${_valueAt(row, validityIndex)} ${whereGranted ?? ''}'.toLowerCase().replaceAll(' ', '');
      final whereIsValidity = whereGranted != null &&
          RegExp(r'^(life|one)').hasMatch(whereGranted.toLowerCase().replaceAll(' ', ''));

      toUpsert.add(
        SaveLicenseHolderRequest(
          permitNo: isBuyer ? '' : permitNo,
          name: name,
          issuedDate: issuedDate,
          whereGranted: whereGranted,
          city: _nullable(_valueAt(row, cityIndex)) ?? (whereIsValidity ? null : whereGranted),
          validity: validityText.contains('onetime') ? LicenseHolderDto.oneTime : LicenseHolderDto.lifetime,
          address: _nullable(_valueAt(row, addressIndex)),
          contactNo: _nullable(_valueAt(row, contactIndex)),
          remark: _nullable(_valueAt(row, remarkIndex)),
          category: isBuyer ? LicenseHolderDto.frequentBuyer : LicenseHolderDto.licenseHolder,
        ),
      );
      imported++;
    }

    if (toUpsert.isNotEmpty) {
      try {
        await _repo.batchUpsertLicenseHolders(toUpsert);
      } catch (e) {
        failed += toUpsert.length;
        imported -= toUpsert.length;
        errors.add('Failed to save imported records: $e');
      }
    }

    return MasterImportSummary(
      target: MasterImportTarget.licenseHolders,
      fileName: fileName,
      imported: imported,
      skipped: skipped,
      failed: failed,
      errors: errors,
    );
  }

  Future<MasterImportSummary> _importMaterials(
    String fileName,
    List<List<String>> rows,
    Map<String, int> headerMap,
  ) async {
    final codeIndex = _requiredIndex(headerMap, const ['localitemcode', 'itemcode', 'scmcode', 'id', 'materialcode']);
    final nameIndex = _requiredIndex(
        headerMap, const ['branddisplayname', 'displayname', 'name', 'materialname', 'brandname', 'itemname']);
    final barcodeIndex = _findIndex(headerMap, const ['barcode', 'scancode']);
    final manufacturerIndex = _findIndex(headerMap, const ['manufacturer', 'maker', 'company']);
    final categoryIndex = _findIndex(headerMap, const ['liquorcategory', 'category']);
    final typeIndex = _findIndex(headerMap, const ['type', 'beertype', 'liquortype']);
    final packingIndex = _findIndex(headerMap, const ['packaging', 'packing', 'size']);
    final counterIndex =
        _findIndex(headerMap, const ['counterbrandname', 'counterbrand', 'countername', 'brandhouse', 'brand']);
    final saleRateIndex = _findIndex(headerMap, const ['salerate', 'rate', 'mrp']);
    final wholesaleIndex = _findIndex(headerMap, const ['wholesalerate', 'wholesale']);
    final taxIndex = _findIndex(headerMap, const ['vat', 'vatpercent', 'taxpercent', 'gst', 'gstpercent', 'tax']);
    final discountIndex = _findIndex(headerMap, const ['discountpercent', 'discount', 'dispercent']);
    final distributorIndex =
        _findIndex(headerMap, const ['distributor', 'distributors', 'defaultdistributor', 'supplier']);

    // Distributor names → supplier ids; unknown names become new suppliers.
    final supplierIdByName = {
      for (final s in await _repo.getSuppliers()) s.name.trim().toLowerCase(): s.id,
    };
    Future<String> supplierIdFor(String rawName) async {
      final name = rawName.trim();
      if (name.isEmpty) return '';
      final known = supplierIdByName[name.toLowerCase()];
      if (known != null) return known;
      final created = await _repo.createSupplier(SaveSupplierRequest(
        name: name,
        disPercent: 0,
        openingBalance: 0,
        balanceType: 'Credit',
      ));
      return supplierIdByName[name.toLowerCase()] = created.id;
    }

    // A material is one SCM code + barcode pair; the same pair again is a skip.
    final existing = {
      for (final m in await _repo.getMaterials()) '${m.scmCode.trim().toLowerCase()}|${m.barcode.trim().toLowerCase()}': true,
    };

    var imported = 0;
    var skipped = 0;
    var failed = 0;
    final errors = <String>[];

    for (var rowNumber = 0; rowNumber < rows.length; rowNumber++) {
      final row = rows[rowNumber];
      final code = _valueAt(row, codeIndex);
      final name = _valueAt(row, nameIndex);

      if (code.isEmpty && name.isEmpty) continue;

      if (code.isEmpty || name.isEmpty) {
        failed++;
        errors.add('Row ${rowNumber + 2}: SCM Code and Name are required.');
        continue;
      }

      // Category decides the brandwise section, so never guess it.
      final category = _nullable(_valueAt(row, categoryIndex));
      if (category == null) {
        failed++;
        errors.add('Row ${rowNumber + 2}: Category is required (e.g. Beer, Wine, Whisky).');
        continue;
      }
      final cat = normalizeLiquorCategory(category, _valueAt(row, typeIndex));
      if (cat.category == 'Beer' && cat.type.isEmpty) {
        failed++;
        errors.add('Row ${rowNumber + 2}: Beer needs a Type (Mild, Strong or Fermented).');
        continue;
      }

      final barcode = _nullable(_valueAt(row, barcodeIndex)) ?? code;
      final pairKey = '${code.toLowerCase()}|${barcode.toLowerCase()}';
      if (existing.containsKey(pairKey)) {
        skipped++;
        continue;
      }

      try {
        await _repo.createMaterial(
          SaveMaterialRequest(
            id: code,
            scmCode: code,
            barcode: barcode,
            name: name,
            manufacturer: _nullable(_valueAt(row, manufacturerIndex)) ?? name.split(' ').first,
            category: cat.category,
            liquorType: cat.type,
            packing: _valueAt(row, packingIndex),
            counterBrandName: _valueAt(row, counterIndex),
            saleRate: _parseDouble(_valueAt(row, saleRateIndex)),
            wholesaleRate: _parseDouble(_valueAt(row, wholesaleIndex)),
            taxPercent: _parseDouble(_valueAt(row, taxIndex)),
            discountPercent: _parseDouble(_valueAt(row, discountIndex)),
            defaultSupplierId: await supplierIdFor(_valueAt(row, distributorIndex)),
          ),
        );
        existing[pairKey] = true;
        imported++;
      } on ApiException catch (e) {
        failed++;
        errors.add('Row ${rowNumber + 2}: ${e.message}');
      } catch (e) {
        failed++;
        errors.add('Row ${rowNumber + 2}: $e');
      }
    }

    return MasterImportSummary(
      target: MasterImportTarget.materials,
      fileName: fileName,
      imported: imported,
      skipped: skipped,
      failed: failed,
      errors: errors,
    );
  }

  Future<MasterImportSummary> _importSuppliers(
    String fileName,
    List<List<String>> rows,
    Map<String, int> headerMap,
  ) async {
    final nameIndex = _requiredIndex(headerMap, const ['name', 'suppliername', 'distributorname']);
    final addressIndex = _findIndex(headerMap, const ['address']);
    final contactIndex = _findIndex(headerMap, const ['contactno', 'contact', 'mobile', 'phone']);
    final emailIndex = _findIndex(headerMap, const ['email', 'emailid']);
    final vatIndex = _findIndex(headerMap, const ['vatno', 'gstno', 'taxno']);
    final bankIndex = _findIndex(headerMap, const ['bankdetails', 'bank']);
    final disIndex = _findIndex(headerMap, const ['dispercent', 'discountpercent', 'discount']);
    final openingIndex = _findIndex(headerMap, const ['openingbalance', 'balance']);
    final balanceTypeIndex = _findIndex(headerMap, const ['balancetype']);

    final existing = {
      for (final supplier in await _repo.getSuppliers()) supplier.name.trim().toLowerCase(): true,
    };

    var imported = 0;
    var skipped = 0;
    var failed = 0;
    final errors = <String>[];

    for (var rowNumber = 0; rowNumber < rows.length; rowNumber++) {
      final row = rows[rowNumber];
      final name = _valueAt(row, nameIndex);

      if (name.isEmpty) {
        if (_rowIsBlank(row)) continue;
        failed++;
        errors.add('Row ${rowNumber + 2}: Supplier name is required.');
        continue;
      }

      if (existing.containsKey(name.toLowerCase())) {
        skipped++;
        continue;
      }

      final rawBalanceType = _nullable(_valueAt(row, balanceTypeIndex)) ?? 'Credit';
      final balanceType = rawBalanceType.toLowerCase() == 'debit' ? 'Debit' : 'Credit';

      try {
        await _repo.createSupplier(
          SaveSupplierRequest(
            name: name,
            address: _nullable(_valueAt(row, addressIndex)),
            contactNo: _nullable(_valueAt(row, contactIndex)),
            email: _nullable(_valueAt(row, emailIndex)),
            vatNo: _nullable(_valueAt(row, vatIndex)),
            bankDetails: _nullable(_valueAt(row, bankIndex)),
            disPercent: _parseDouble(_valueAt(row, disIndex)),
            openingBalance: _parseDouble(_valueAt(row, openingIndex)),
            balanceType: balanceType,
          ),
        );
        existing[name.toLowerCase()] = true;
        imported++;
      } on ApiException catch (e) {
        failed++;
        errors.add('Row ${rowNumber + 2}: ${e.message}');
      } catch (e) {
        failed++;
        errors.add('Row ${rowNumber + 2}: $e');
      }
    }

    return MasterImportSummary(
      target: MasterImportTarget.suppliers,
      fileName: fileName,
      imported: imported,
      skipped: skipped,
      failed: failed,
      errors: errors,
    );
  }

  /// Rows of the first non-empty sheet (or the CSV), as trimmed strings.
  /// Also used by onboarding to read a closing-stock sheet.
  Future<List<List<String>>> readRows(XFile file) async {
    final extension = file.name.split('.').last.toLowerCase();
    final bytes = await file.readAsBytes();
    if (extension == 'csv') {
      return _parseCsv(utf8.decode(bytes));
    }
    // "XML Spreadsheet 2003" — what Caskly's own report exports (.xls).
    final head = utf8.decode(bytes.take(512).toList(), allowMalformed: true).trimLeft();
    if (head.startsWith('<?xml') || head.startsWith('<Workbook')) {
      return readSpreadsheetMl(utf8.decode(bytes, allowMalformed: true));
    }
    // Old binary .xls (Excel 97–2003) can't be read directly.
    if (bytes.length > 4 && bytes[0] == 0xD0 && bytes[1] == 0xCF && bytes[2] == 0x11 && bytes[3] == 0xE0) {
      throw const FormatException(
          'This is an old-style Excel file (.xls). Open it in Excel, choose File → Save As → '
          'Excel Workbook (.xlsx), and import that copy.');
    }

    final workbook = Excel.decodeBytes(bytes);
    for (final table in workbook.tables.values) {
      if (table.rows.isEmpty) continue;
      return table.rows
          .map(
            (row) => row
                .map((cell) => _cellToString(cell?.value))
                .toList(),
          )
          .toList();
    }
    return const [];
  }

  /// Rows of the first worksheet of an XML Spreadsheet 2003 file. Honors
  /// `ss:Index` (absolute column) and `ss:MergeAcross` (merged cells), so
  /// columns line up exactly as Excel shows them.
  static List<List<String>> readSpreadsheetMl(String source) {
    final doc = XmlDocument.parse(source);
    final sheet = doc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'Worksheet').firstOrNull;
    if (sheet == null) return const [];
    final out = <List<String>>[];
    for (final row in sheet.descendants.whereType<XmlElement>().where((e) => e.name.local == 'Row')) {
      final rowIndex = _ssAttr(row, 'Index');
      if (rowIndex != null) {
        while (out.length < int.parse(rowIndex) - 1) {
          out.add(<String>[]);
        }
      }
      final cells = <String>[];
      for (final cell in row.childElements.where((e) => e.name.local == 'Cell')) {
        final index = _ssAttr(cell, 'Index');
        if (index != null) {
          while (cells.length < int.parse(index) - 1) {
            cells.add('');
          }
        }
        final data = cell.childElements.where((e) => e.name.local == 'Data').firstOrNull;
        cells.add(data?.innerText.trim() ?? '');
        final merge = int.tryParse(_ssAttr(cell, 'MergeAcross') ?? '') ?? 0;
        for (var i = 0; i < merge; i++) {
          cells.add('');
        }
      }
      out.add(cells);
    }
    return out;
  }

  static String? _ssAttr(XmlElement e, String name) =>
      e.attributes.where((a) => a.name.local == name).firstOrNull?.value;

  List<List<String>> _parseCsv(String raw) {
    final lines = const LineSplitter().convert(raw).where((line) => line.trim().isNotEmpty).toList();
    return lines.map(_parseCsvLine).toList();
  }

  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }
      if (char == ',' && !inQuotes) {
        values.add(buffer.toString().trim());
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }

    values.add(buffer.toString().trim());
    return values;
  }

  Map<String, int> _buildHeaderMap(List<String> headerRow) {
    final map = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final normalized = _normalizeHeader(headerRow[i]);
      if (normalized.isNotEmpty) {
        map[normalized] = i;
      }
    }
    return map;
  }

  int _requiredIndex(Map<String, int> headers, List<String> aliases) {
    final index = _findIndex(headers, aliases);
    if (index == null) {
      throw ApiException('Missing required column. Expected one of: ${aliases.join(', ')}');
    }
    return index;
  }

  int? _findIndex(Map<String, int> headers, List<String> aliases) {
    for (final alias in aliases) {
      final normalized = _normalizeHeader(alias);
      final index = headers[normalized];
      if (index != null) return index;
    }
    return null;
  }

  String _normalizeHeader(String input) => input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  String _valueAt(List<String> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return '';
    return row[index].trim();
  }

  String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();

  bool _rowIsBlank(List<String> row) => row.every((value) => value.trim().isEmpty);

  double _parseDouble(String raw) {
    if (raw.trim().isEmpty) return 0;
    final normalized = raw.replaceAll(',', '').replaceAll('%', '').trim();
    return double.tryParse(normalized) ?? 0;
  }

  String _cellToString(CellValue? value) {
    if (value == null) return '';
    if (value is TextCellValue) return value.value.toString();
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) return value.value.toString();
    if (value is BoolCellValue) return value.value ? 'true' : 'false';
    if (value is FormulaCellValue) return value.formula;
    if (value is DateCellValue) return '${value.day}/${value.month}/${value.year}';
    if (value is TimeCellValue) return '${value.hour}:${value.minute}:${value.second}';
    if (value is DateTimeCellValue) {
      return '${value.day}/${value.month}/${value.year} ${value.hour}:${value.minute}:${value.second}';
    }
    return '$value';
  }
}
