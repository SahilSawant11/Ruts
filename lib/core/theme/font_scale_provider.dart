import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available font scale presets tailored for POS counter visibility.
enum AppFontScale {
  compact(
    label: 'Compact',
    description: 'Dense tables & small screens',
    scale: 0.90,
    percentage: '90%',
  ),
  standard(
    label: 'Standard',
    description: 'Default POS baseline',
    scale: 1.00,
    percentage: '100%',
  ),
  comfortable(
    label: 'Comfortable',
    description: 'Arm-length counter viewing',
    scale: 1.12,
    percentage: '112%',
  ),
  large(
    label: 'Large',
    description: 'High legibility touch screen',
    scale: 1.25,
    percentage: '125%',
  ),
  extraLarge(
    label: 'Extra Large',
    description: 'Kiosk & high-visibility mode',
    scale: 1.35,
    percentage: '135%',
  );

  const AppFontScale({
    required this.label,
    required this.description,
    required this.scale,
    required this.percentage,
  });

  final String label;
  final String description;
  final double scale;
  final String percentage;

  static AppFontScale fromScale(double scale) {
    AppFontScale closest = AppFontScale.standard;
    double minDiff = double.infinity;
    for (final preset in AppFontScale.values) {
      final diff = (preset.scale - scale).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = preset;
      }
    }
    return closest;
  }
}

/// Controller managing font scaling across the app.
class FontScaleNotifier extends StateNotifier<double> {
  FontScaleNotifier() : super(1.00);

  static const List<double> supportedScales = [0.90, 1.00, 1.12, 1.25, 1.35];

  void setScale(double scale) {
    state = scale.clamp(0.85, 1.40);
  }

  void setPreset(AppFontScale preset) {
    state = preset.scale;
  }

  void increase() {
    final next = supportedScales.firstWhere(
      (s) => s > state + 0.01,
      orElse: () => supportedScales.last,
    );
    state = next;
  }

  void decrease() {
    final prev = supportedScales.lastWhere(
      (s) => s < state - 0.01,
      orElse: () => supportedScales.first,
    );
    state = prev;
  }

  void reset() {
    state = 1.00;
  }
}

/// Global provider for dynamic font scaling.
final appFontScaleProvider =
    StateNotifierProvider<FontScaleNotifier, double>((ref) {
  return FontScaleNotifier();
});
