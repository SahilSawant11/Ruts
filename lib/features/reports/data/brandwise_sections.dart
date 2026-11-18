// Shared section rules for the Brandwise and Counter Brandwise registers.

/// Display order of the register's sections.
const brandwiseSectionOrder = ['FERMENTED BEER', 'STRONG BEER', 'MILD BEER', 'WINE'];

/// Maps a material's `category` (case-insensitive) to its register section,
/// or `null` for items the register doesn't carry (e.g. soft drinks).
String? brandwiseSection(String category) {
  final lower = category.toLowerCase().trim();
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

/// Distinct, non-empty TP numbers joined in first-seen order ("TP1, TP2"),
/// or `null` when there are none.
String? joinTpNos(Iterable<String?> tpNos) {
  final seen = <String>{};
  for (final tp in tpNos) {
    final t = tp?.trim() ?? '';
    if (t.isNotEmpty) seen.add(t);
  }
  return seen.isEmpty ? null : seen.join(', ');
}
