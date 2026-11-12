import 'opening_stock_service.dart';

/// Reads the excise "BRANDWISE STOCK REPORT" register (the same layout
/// Caskly's own Brandwise report exports): brand rows grouped under
/// category headers, with OPENING BALANCE / PURCHASE / SALE / CLOSING
/// BALANCE groups, each split into size columns (750ml … 330ml).
///
/// Every brand × size that has a number anywhere in the row becomes a
/// product; its quantity is the CLOSING BALANCE figure (blank = 0), so
/// sold-out brands still get added and can be purchased on day one.
///
/// The register has no SCM codes or MRPs. Products get a stable code made
/// from brand + size (so re-importing matches the same products) and no
/// price; the owner sets prices in Masters before billing.
abstract final class BrandwiseStockParser {
  /// Returns null when [rows] aren't a brandwise register, so the caller
  /// can fall back to a plain one-row-per-product sheet.
  static List<ClosingStockRow>? tryParse(List<List<String>> rows, {List<String>? problems}) {
    // 1. The group header row: has CLOSING BALANCE and BRAND NAME.
    int? headerRow;
    int? closingCol;
    int? brandCol;
    for (var r = 0; r < rows.length && r < 15; r++) {
      final row = rows[r];
      final closing = row.indexWhere((c) => _norm(c).startsWith('closing'));
      final brand = row.indexWhere((c) => _norm(c) == 'brandname' || _norm(c) == 'brand');
      if (closing >= 0 && brand >= 0) {
        headerRow = r;
        closingCol = closing;
        brandCol = brand;
        break;
      }
    }
    if (headerRow == null || closingCol == null || brandCol == null) return null;

    // 2. The size row: the first row below with size labels in the
    //    closing group.
    int? sizeRow;
    for (var r = headerRow + 1; r < rows.length && r <= headerRow + 4; r++) {
      if (_sizeAt(rows[r], closingCol) != null) {
        sizeRow = r;
        break;
      }
    }
    if (sizeRow == null) return null;
    final sizes = rows[sizeRow];

    // Closing columns: consecutive size labels from the CLOSING header on.
    final closingBySize = <String, int>{};
    for (var c = closingCol; c < sizes.length; c++) {
      final size = _sizeAt(sizes, c);
      if (size == null) break;
      closingBySize.putIfAbsent(size, () => c);
    }
    // Every column of each size, across all groups (opening, purchase …).
    final allBySize = <String, List<int>>{};
    for (var c = 0; c < sizes.length; c++) {
      final size = _sizeAt(sizes, c);
      if (size != null) allBySize.putIfAbsent(size, () => []).add(c);
    }

    final out = <ClosingStockRow>[];
    var category = '';
    for (var r = sizeRow + 1; r < rows.length; r++) {
      final row = rows[r];
      final filled = [for (final v in row) if (v.trim().isNotEmpty) v.trim()];
      if (filled.isEmpty) continue;
      final brand = brandCol < row.length ? row[brandCol].trim() : '';

      // A lone label is a category header ("FERMENTED BEER").
      if (filled.length == 1 && _num(filled.single) == null) {
        category = _titleCase(filled.single);
        continue;
      }
      if (brand.isEmpty || _norm(brand).contains('total')) continue;

      for (final entry in closingBySize.entries) {
        final size = entry.key;
        final used = allBySize[size]!.any((c) => (_num(_at(row, c)) ?? 0) != 0);
        if (!used) continue;
        final raw = _at(row, entry.value);
        final qty = raw.isEmpty ? 0 : _num(raw);
        if (qty == null || qty != qty.roundToDouble()) {
          problems?.add('Row ${r + 1}: "$brand" $size closing "$raw" is not a whole number of bottles.');
          continue;
        }
        if (qty < 0) {
          problems?.add('Row ${r + 1}: "$brand" $size closing stock can\'t be negative.');
          continue;
        }
        if (category.isEmpty) {
          problems?.add('Row ${r + 1}: "$brand" is above the first category heading, so its category is unknown.');
          continue;
        }
        out.add(ClosingStockRow(
          rowNumber: r + 1,
          code: codeFor(brand, size),
          name: brand,
          category: category,
          packing: size,
          saleRate: 0,
          qty: qty.round(),
        ));
      }
    }
    return out;
  }

  /// Stable product code from brand + size, e.g. KINGFISHERSTRONG-650,
  /// KINGFISHERSTRONG-500C (C = can).
  static String codeFor(String brand, String packing) {
    final b = brand.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final ml = RegExp(r'\d+').firstMatch(packing)?.group(0) ?? '';
    final can = packing.toUpperCase().contains('CAN') ? 'C' : '';
    return '${b.length > 24 ? b.substring(0, 24) : b}-$ml$can';
  }

  /// "500ml (CAN)" → "500 ML (CAN)" (the app's packing names); null if
  /// the cell isn't a size label.
  static String? _sizeAt(List<String> row, int c) {
    final v = _at(row, c).toUpperCase().replaceAll(RegExp(r'\s+'), '');
    final m = RegExp(r'^(\d{2,4})ML(\(?CAN\)?)?$').firstMatch(v);
    if (m == null) return null;
    return '${m.group(1)} ML${m.group(2) != null ? ' (CAN)' : ''}';
  }

  static String _at(List<String> row, int c) => c < row.length ? row[c].trim() : '';

  static double? _num(String s) => double.tryParse(s.replaceAll(',', '').trim());

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static String _titleCase(String s) => s
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
