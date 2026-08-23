String deriveInventoryManufacturer(String itemName) {
  final normalized = itemName.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) return '';

  final words = normalized.split(' ');
  if (words.length == 1) return words.first;

  final firstTwo = '${words[0]} ${words[1]}'.toLowerCase();
  const compoundManufacturers = {
    'royal stag',
    'blenders pride',
    'magic moments',
    'old monk',
    'royal challenge',
    '100 pipers',
    'teacher\'s highland',
    'johnnie walker',
    'coca-cola can',
    'coca-cola',
  };

  if (compoundManufacturers.contains(firstTwo)) {
    return '${words[0]} ${words[1]}';
  }

  return words.first;
}
