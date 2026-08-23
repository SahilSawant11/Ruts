import 'dart:convert';

import 'package:excel_community/excel_community.dart';
import 'package:file_selector/file_selector.dart';

import '../../../core/network/api_exception.dart';
import 'local_masters_repository.dart';
import 'models/save_material_request.dart';
import 'models/save_supplier_request.dart';

enum MasterImportTarget { materials, suppliers }

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

  String get entityLabel => target == MasterImportTarget.materials ? 'materials' : 'suppliers';

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
    final rows = await _readRows(file);
    if (rows.length < 2) {
      throw const ApiException('The selected file does not contain any data rows.');
    }

    final headerMap = _buildHeaderMap(rows.first);
    return switch (target) {
      MasterImportTarget.materials => _importMaterials(file.name, rows.skip(1).toList(), headerMap),
      MasterImportTarget.suppliers => _importSuppliers(file.name, rows.skip(1).toList(), headerMap),
    };
  }

  Future<MasterImportSummary> _importMaterials(
    String fileName,
    List<List<String>> rows,
    Map<String, int> headerMap,
  ) async {
    final codeIndex = _requiredIndex(headerMap, const ['localitemcode', 'itemcode', 'id', 'materialcode']);
    final nameIndex = _requiredIndex(headerMap, const ['name', 'materialname', 'brandname', 'itemname']);
    final barcodeIndex = _findIndex(headerMap, const ['barcode', 'scancode']);
    final manufacturerIndex = _findIndex(headerMap, const ['manufacturer', 'brand', 'maker', 'company']);
    final categoryIndex = _findIndex(headerMap, const ['category', 'type']);
    final packingIndex = _findIndex(headerMap, const ['packing', 'size']);
    final saleRateIndex = _findIndex(headerMap, const ['salerate', 'rate', 'mrp']);
    final taxIndex = _findIndex(headerMap, const ['taxpercent', 'gst', 'gstpercent', 'tax']);

    final existing = {
      for (final material in await _repo.getMaterials()) material.id.trim().toLowerCase(): true,
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
        errors.add('Row ${rowNumber + 2}: Local Item Code and Name are required.');
        continue;
      }

      if (existing.containsKey(code.toLowerCase())) {
        skipped++;
        continue;
      }

      try {
        await _repo.createMaterial(
          SaveMaterialRequest(
            id: code,
            barcode: _nullable(_valueAt(row, barcodeIndex)) ?? code,
            name: name,
            manufacturer: _nullable(_valueAt(row, manufacturerIndex)) ?? name.split(' ').first,
            category: _nullable(_valueAt(row, categoryIndex)) ?? 'Beer',
            packing: _valueAt(row, packingIndex),
            saleRate: _parseDouble(_valueAt(row, saleRateIndex)),
            taxPercent: _parseDouble(_valueAt(row, taxIndex)),
          ),
        );
        existing[code.toLowerCase()] = true;
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

  Future<List<List<String>>> _readRows(XFile file) async {
    final extension = file.name.split('.').last.toLowerCase();
    final bytes = await file.readAsBytes();
    if (extension == 'csv') {
      return _parseCsv(utf8.decode(bytes));
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
