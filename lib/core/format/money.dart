/// Indian-style number formatting: 1,23,45,678.90 (lakh / crore grouping).
abstract final class Money {
  /// ₹1,23,456.00 — use for every rupee amount shown to users.
  static String inr(num value, {int decimals = 2, bool symbol = true}) {
    final neg = value < 0;
    final body = group(value.abs(), decimals: decimals);
    return '${neg ? '-' : ''}${symbol ? '₹' : ''}$body';
  }

  /// 1,23,456.00 without the symbol (table cells under a ₹ header).
  static String plain(num value, {int decimals = 2}) => inr(value, decimals: decimals, symbol: false);

  /// Short form for cards and chart axes: ₹950, ₹12,450, ₹1.25 L, ₹3.4 Cr.
  static String compact(num value, {bool symbol = true}) {
    final v = value.abs();
    final sign = value < 0 ? '-' : '';
    final sym = symbol ? '₹' : '';
    String trim(String s) => s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
    if (v >= 10000000) return '$sign$sym${trim((v / 10000000).toStringAsFixed(2))} Cr';
    if (v >= 100000) return '$sign$sym${trim((v / 100000).toStringAsFixed(2))} L';
    return '$sign$sym${group(v, decimals: 0)}';
  }

  /// For editable number fields: 1180 not 1180.0, 18.5 stays 18.5,
  /// 12.345 → 12.35. No grouping (the field must parse back).
  static String editable(num value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    final s = value.toStringAsFixed(2);
    return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
  }

  /// Groups an absolute value in the Indian system.
  static String group(num value, {int decimals = 2}) {
    final fixed = value.toStringAsFixed(decimals);
    final dot = fixed.indexOf('.');
    final intPart = dot == -1 ? fixed : fixed.substring(0, dot);
    final frac = dot == -1 ? '' : fixed.substring(dot);
    if (intPart.length <= 3) return '$intPart$frac';
    final last3 = intPart.substring(intPart.length - 3);
    var rest = intPart.substring(0, intPart.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3$frac';
  }
}
