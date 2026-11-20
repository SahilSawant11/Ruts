// Shared section rules for the Brandwise and Counter Brandwise registers.

/// Display order of the register's sections.
const brandwiseSectionOrder = ['FERMENTED BEER', 'STRONG BEER', 'MILD BEER', 'WINE'];

/// Maps a material's `category` + beer `type` (case-insensitive) to its
/// register section, or `null` for items the register doesn't carry (e.g.
/// soft drinks). Older rows with "Strong Beer" in the category still work.
String? brandwiseSection(String category, [String type = '']) {
  final lower = '$type $category'.toLowerCase().trim();
  if (lower.contains('fermented')) return 'FERMENTED BEER';
  if (lower.contains('strong')) return 'STRONG BEER';
  if (lower.contains('mild')) return 'MILD BEER';
  if (lower.contains('wine') || lower.contains('whisky') || lower.contains('whiskey') ||
      lower.contains('rum') || lower.contains('vodka') || lower.contains('brandy') ||
      lower.contains('gin')) {
    return 'WINE';
  }
  // Plain "Beer" with no strength stays in Mild, as before.
  if (lower.contains('beer')) return 'MILD BEER';
  return null;
}


/// One register row's purchase: a TP number and its qty per size column.
typedef TpPurchase = ({String? tpNo, List<int> qty});

/// A brand's purchases on the report day, kept apart per TP (in bill order)
/// so two TPs on the same day print as two register rows.
class TpPurchaseSplit {
  TpPurchaseSplit([this.width = 7]);

  /// Number of size columns (7 standard + the report's extra sizes).
  final int width;
  final _byTp = <String, List<int>>{};

  void add(String? tpNo, int col, int qty) {
    final key = tpNo?.trim() ?? '';
    (_byTp[key] ??= List<int>.filled(width, 0))[col] += qty;
  }

  /// One entry per TP; a single empty entry when nothing was purchased.
  /// [order] lists the day's TP numbers as they arrived: rows follow it, so
  /// a line merged from several drinks still reads in arrival order.
  List<TpPurchase> rows([List<String>? order]) {
    if (_byTp.isEmpty) return [(tpNo: null, qty: List<int>.filled(width, 0))];
    final keys = _byTp.keys.toList();
    if (order != null) {
      int rank(String k) {
        final i = order.indexOf(k);
        return i < 0 ? order.length : i;
      }
      final firstSeen = {for (var i = 0; i < keys.length; i++) keys[i]: i};
      keys.sort((a, b) {
        final byOrder = rank(a).compareTo(rank(b));
        return byOrder != 0 ? byOrder : firstSeen[a]!.compareTo(firstSeen[b]!);
      });
    }
    return [
      for (final k in keys) (tpNo: k.isEmpty ? null : k, qty: _byTp[k]!),
    ];
  }
}

/// The register's 7 standard size columns, as printed.
const standardSizeLabels = ['750ml', '375ml', '180ml', '650ml', '500ml (CAN)', '330ml (CAN)', '330ml'];

/// Standard register column (0–6) for a packing like "750 ML", "500ml CAN",
/// "330 ML (CAN)"; -1 when the size has no register column.
int registerColumn(String? packing) {
  final size = _sizeOf(packing);
  if (size == null) return -1;
  return switch (size.ml) {
    750 => 0,
    375 => 1,
    180 => 2,
    650 => 3,
    500 => 4,
    330 => size.isCan ? 5 : 6,
    _ => -1,
  };
}

/// Column label for a size with no register column: "1000ml", "2000ml
/// (CAN)", or the packing as typed when it has no number.
String extraSizeLabel(String packing) {
  final size = _sizeOf(packing);
  if (size == null) return packing.trim().toUpperCase();
  return '${size.ml}ml${size.isCan ? ' (CAN)' : ''}';
}

/// Orders extra size labels largest first, like the register.
int compareSizeLabels(String a, String b) {
  final x = int.tryParse(RegExp(r'^\d+').stringMatch(a) ?? '') ?? 0;
  final y = int.tryParse(RegExp(r'^\d+').stringMatch(b) ?? '') ?? 0;
  return x != y ? y.compareTo(x) : a.compareTo(b);
}

({int ml, bool isCan})? _sizeOf(String? packing) {
  if (packing == null || packing.trim().isEmpty) return null;
  final n = packing.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final m = RegExp(r'(\d+(?:\.\d+)?)(ml|ltr|lt|l)?').firstMatch(n);
  if (m == null) return null;
  final value = double.tryParse(m.group(1)!) ?? 0;
  final unit = m.group(2) ?? 'ml';
  final ml = unit == 'ml' ? value.round() : (value * 1000).round();
  return (ml: ml, isCan: n.contains('can'));
}
