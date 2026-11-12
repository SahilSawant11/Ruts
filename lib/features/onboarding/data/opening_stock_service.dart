import 'dart:convert';

import 'package:drift/drift.dart' show InsertMode, Value;
import 'package:file_selector/file_selector.dart';

import '../../../core/local/app_database.dart';
import '../../masters/data/local_masters_repository.dart';
import '../../masters/data/master_import_service.dart';
import '../../masters/data/models/save_material_request.dart';
import '../../sales/data/models/material_dto.dart';
import 'brandwise_stock_parser.dart';

/// One data row of a closing-stock sheet exported from the store's old
/// software (or typed up by hand).
class ClosingStockRow {
  const ClosingStockRow({
    required this.rowNumber,
    required this.code,
    required this.name,
    required this.category,
    required this.packing,
    required this.saleRate,
    required this.qty,
  });

  /// 1-based spreadsheet row, for messages the owner can find.
  final int rowNumber;
  final String code;
  final String name;
  final String category;
  final String packing;
  final double saleRate;
  final int qty;
}

/// A closing-stock sheet matched against this store's products.
class ClosingStockMatch {
  const ClosingStockMatch({
    required this.qtyByMaterial,
    required this.newProducts,
    required this.problems,
  });

  /// Existing product id → closing quantity (duplicate rows are summed).
  final Map<String, int> qtyByMaterial;

  /// Rows for products this store doesn't have yet but which carry enough
  /// detail (code, name, category, size) to be created on confirm.
  final List<ClosingStockRow> newProducts;

  /// Rows that could not be used, in plain words.
  final List<String> problems;

  int get matchedCount => qtyByMaterial.length;
}

/// First-run setup: the store enters its closing stock from the old system
/// once, and Caskly continues from there.
///
/// Reports need nothing special: they work back from stock on hand
/// (opening = closing + sales − purchases), so setting stock on hand at
/// go-live makes day one's opening balance correct.
class OpeningStockService {
  OpeningStockService(this._db, this._masters, this._import, {this.onStockChanged});

  final AppDatabase _db;
  final LocalMastersRepository _masters;
  final MasterImportService _import;

  /// Refreshes in-memory caches that hold stock (the billing lookup cache).
  final Future<void> Function()? onStockChanged;

  static const completeKey = 'onboarding_complete';
  static const goLiveKey = 'go_live_date';
  static const auditKey = 'opening_stock_audit';

  /// True only for a store that has never finished setup and has no bills.
  /// A store that already has bills is marked done and never sees setup.
  Future<bool> needsOnboarding() async {
    if (await _db.getSetting(completeKey) != null) return false;
    if (await _hasAnyBills()) {
      await _db.setSetting(completeKey, 'existing-data');
      return false;
    }
    return true;
  }

  Future<bool> _hasAnyBills() async {
    for (final table in const ['cached_sales_bills', 'cached_purchase_bills']) {
      final rows = await _db.customSelect('SELECT 1 FROM $table LIMIT 1').get();
      if (rows.isNotEmpty) return true;
    }
    return false;
  }

  /// Current stock on hand per product (to prefill the entry grid).
  Future<Map<String, int>> currentStock() async {
    final rows = await _db.select(_db.cachedInventoryStocks).get();
    return {for (final r in rows) r.materialId: r.qtyOnHand};
  }

  // ── Reading a sheet ──────────────────────────────────────────────────

  static const _codeAliases = ['scmcode', 'localitemcode', 'itemcode', 'code', 'materialcode', 'id', 'barcode'];
  static const _nameAliases = ['brandname', 'itemname', 'materialname', 'productname', 'name', 'brand', 'product'];
  static const _qtyAliases = [
    'closingstock', 'closingqty', 'closingbalance', 'closing', 'balance', 'qtyonhand',
    'stock', 'qty', 'quantity', 'bottles',
  ];
  static const _categoryAliases = ['category', 'type'];
  static const _packingAliases = ['packing', 'size', 'pack', 'ml'];
  static const _rateAliases = ['mrp', 'salerate', 'rate'];

  Future<List<ClosingStockRow>> readSheet(XFile file, {List<String>? problems}) async =>
      parseRows(await _import.readRows(file), problems: problems);

  /// Parses rows (header first). Needs a quantity column and a code or
  /// name column; everything else is optional.
  /// A brandwise stock register (brand rows × size columns) is detected
  /// and read first; otherwise the sheet is one row per product.
  static List<ClosingStockRow> parseRows(List<List<String>> rows, {List<String>? problems}) {
    if (rows.length < 2) throw const FormatException('The file has no data rows.');
    final brandwise = BrandwiseStockParser.tryParse(rows, problems: problems);
    if (brandwise != null) {
      if (brandwise.isEmpty) {
        throw const FormatException('This brandwise report has no brands with stock in it.');
      }
      return brandwise;
    }
    final header = <String, int>{};
    for (var i = 0; i < rows.first.length; i++) {
      final key = _norm(rows.first[i]);
      if (key.isNotEmpty) header.putIfAbsent(key, () => i);
    }
    int? find(List<String> aliases) {
      for (final a in aliases) {
        final i = header[a];
        if (i != null) return i;
      }
      return null;
    }

    final qtyIdx = find(_qtyAliases);
    final codeIdx = find(_codeAliases);
    final nameIdx = find(_nameAliases);
    if (qtyIdx == null) {
      throw const FormatException('Could not find a closing stock column. Name it "Closing Stock" or "Qty".');
    }
    if (codeIdx == null && nameIdx == null) {
      throw const FormatException('Could not find a product column. Add "SCM Code" or "Brand Name".');
    }
    final catIdx = find(_categoryAliases), packIdx = find(_packingAliases), rateIdx = find(_rateAliases);

    String at(List<String> row, int? i) => (i == null || i >= row.length) ? '' : row[i].trim();

    final out = <ClosingStockRow>[];
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.every((v) => v.trim().isEmpty)) continue;
      final code = at(row, codeIdx), name = at(row, nameIdx), rawQty = at(row, qtyIdx);
      if (code.isEmpty && name.isEmpty) continue; // totals / blank label rows
      final qty = _parseQty(rawQty);
      if (qty == null) {
        problems?.add('Row ${r + 1}: "$rawQty" is not a whole number of bottles.');
        continue;
      }
      if (qty < 0) {
        problems?.add('Row ${r + 1}: closing stock can\'t be negative ($qty).');
        continue;
      }
      out.add(ClosingStockRow(
        rowNumber: r + 1,
        code: code,
        name: name,
        category: at(row, catIdx),
        packing: at(row, packIdx),
        saleRate: double.tryParse(at(row, rateIdx).replaceAll(',', '')) ?? 0,
        qty: qty,
      ));
    }
    return out;
  }

  /// Blank counts as 0 (old systems leave sold-out lines empty); "12.0"
  /// from Excel is fine; "12.5" or text is rejected.
  static int? _parseQty(String raw) {
    final s = raw.replaceAll(',', '').trim();
    if (s.isEmpty) return 0;
    final d = double.tryParse(s);
    if (d == null || d != d.roundToDouble()) return null;
    return d.round();
  }

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  // ── Matching ────────────────────────────────────────────────────────

  /// Matches rows to products by SCM code, then barcode, then name + size.
  static ClosingStockMatch match(List<ClosingStockRow> rows, List<MaterialDto> materials) {
    final byCode = <String, MaterialDto>{};
    final byBarcode = <String, MaterialDto>{};
    final byNameSize = <String, MaterialDto>{};
    for (final m in materials) {
      byCode[m.id.trim().toLowerCase()] = m;
      if (m.barcode.trim().isNotEmpty) byBarcode.putIfAbsent(m.barcode.trim().toLowerCase(), () => m);
      byNameSize.putIfAbsent('${_norm(m.name)}|${_norm(m.packing)}', () => m);
    }

    final qty = <String, int>{};
    final newProducts = <String, ClosingStockRow>{};
    final problems = <String>[];
    for (final row in rows) {
      final code = row.code.toLowerCase();
      final m = (code.isEmpty ? null : byCode[code] ?? byBarcode[code]) ??
          (row.name.isEmpty ? null : byNameSize['${_norm(row.name)}|${_norm(row.packing)}']);
      if (m != null) {
        qty[m.id] = (qty[m.id] ?? 0) + row.qty;
        continue;
      }
      final missing = [
        if (row.code.isEmpty) 'SCM code',
        if (row.name.isEmpty) 'name',
        if (row.category.isEmpty) 'category',
        if (row.packing.isEmpty) 'size',
      ];
      if (missing.isNotEmpty) {
        final label = row.name.isNotEmpty ? row.name : row.code;
        problems.add('Row ${row.rowNumber}: "$label" isn\'t in your products, and the row has no ${missing.join(', ')} to add it.');
        continue;
      }
      final prev = newProducts[code];
      newProducts[code] = prev == null
          ? row
          : ClosingStockRow(
              rowNumber: prev.rowNumber, code: prev.code, name: prev.name, category: prev.category,
              packing: prev.packing, saleRate: prev.saleRate, qty: prev.qty + row.qty);
    }
    return ClosingStockMatch(qtyByMaterial: qty, newProducts: newProducts.values.toList(), problems: problems);
  }

  // ── Saving ──────────────────────────────────────────────────────────

  /// Creates any new products, sets stock on hand for every product in
  /// [qtyByMaterial], records an audit entry and marks setup complete.
  Future<void> apply({
    required DateTime asOf,
    required Map<String, int> qtyByMaterial,
    List<ClosingStockRow> newProducts = const [],
    required String enteredBy,
  }) async {
    final quantities = Map<String, int>.of(qtyByMaterial);
    for (final p in newProducts) {
      await _masters.createMaterial(SaveMaterialRequest(
        id: p.code,
        name: p.name,
        manufacturer: p.name.split(' ').first,
        category: p.category,
        packing: p.packing,
        saleRate: p.saleRate,
        taxPercent: 0,
      ));
      quantities[p.code] = (quantities[p.code] ?? 0) + p.qty;
    }

    final materials = {for (final m in await _masters.getMaterials()) m.id: m};
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      final existing = {for (final r in await _db.select(_db.cachedInventoryStocks).get()) r.materialId: r};
      for (final e in quantities.entries) {
        final m = materials[e.key];
        if (m == null) continue;
        await _db.into(_db.cachedInventoryStocks).insert(
              CachedInventoryStocksCompanion.insert(
                materialId: m.id,
                barcode: m.barcode,
                name: m.name,
                category: m.category,
                qtyOnHand: e.value,
                reorderLevel: Value(existing[m.id]?.reorderLevel ?? 10),
                updatedAt: Value(now),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
      final day = DateTime(asOf.year, asOf.month, asOf.day);
      final total = quantities.values.fold<int>(0, (a, b) => a + b);
      await _db.setSetting(goLiveKey, day.toIso8601String().substring(0, 10));
      await _db.setSetting(
        auditKey,
        jsonEncode({
          'asOf': day.toIso8601String().substring(0, 10),
          'enteredBy': enteredBy,
          'enteredAt': now.toIso8601String(),
          'products': quantities.values.where((q) => q > 0).length,
          'bottles': total,
          'newProducts': newProducts.length,
          'stock': quantities,
        }),
      );
      await _db.setSetting(completeKey, now.toIso8601String());
    });
    await onStockChanged?.call();
  }
}
