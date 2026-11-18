// Liquor category + type rules for the material master.
//
// Category is the liquor (Beer, Wine, Whisky…). Type is only used for beer
// today: Mild / Strong / Fermented — it decides the beer section of the
// brandwise register.

const beerTypes = ['Mild', 'Strong', 'Fermented'];

bool isBeerCategory(String category) => category.toLowerCase().contains('beer');

/// Normalises a category/type pair. Older data and Excel files say
/// "Strong Beer" in the category; that becomes category `Beer`, type
/// `Strong`. Non-beer categories never carry a type.
({String category, String type}) normalizeLiquorCategory(String category, [String type = '']) {
  final c = category.trim();
  if (!isBeerCategory(c)) return (category: c, type: '');
  final t = _beerType(type) ?? _beerType(c) ?? '';
  return (category: 'Beer', type: t);
}

String? _beerType(String raw) {
  final lower = raw.toLowerCase();
  for (final t in beerTypes) {
    if (lower.contains(t.toLowerCase())) return t;
  }
  return null;
}
