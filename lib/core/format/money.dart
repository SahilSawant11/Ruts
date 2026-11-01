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
