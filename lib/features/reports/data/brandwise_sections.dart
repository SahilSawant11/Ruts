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
  final _byTp = <String, List<int>>{};

  void add(String? tpNo, int col, int qty) {
    final key = tpNo?.trim() ?? '';
    (_byTp[key] ??= List<int>.filled(7, 0))[col] += qty;
  }

  /// One entry per TP; a single empty entry when nothing was purchased.
  List<TpPurchase> rows() {
    if (_byTp.isEmpty) return [(tpNo: null, qty: List<int>.filled(7, 0))];
    return [
      for (final e in _byTp.entries) (tpNo: e.key.isEmpty ? null : e.key, qty: e.value),
    ];
  }
}
