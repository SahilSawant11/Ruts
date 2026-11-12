import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import 'font_scale_provider.dart';
import 'theme_mode_provider.dart';

const _themeKey = 'appearance_theme_mode';
const _fontScaleKey = 'appearance_font_scale';

/// Loads the saved theme and text size, then saves every later change,
/// whether it comes from Settings or the header toggles.
Future<void> restoreAndPersistAppearance(Ref ref, AppDatabase db) async {
  final theme = await db.getSetting(_themeKey);
  final mode = ThemeMode.values.where((m) => m.name == theme).firstOrNull;
  if (mode != null) ref.read(appThemeModeProvider.notifier).state = mode;

  final scale = double.tryParse(await db.getSetting(_fontScaleKey) ?? '');
  if (scale != null) ref.read(appFontScaleProvider.notifier).setScale(scale);

  ref.listen<ThemeMode>(appThemeModeProvider, (_, m) => db.setSetting(_themeKey, m.name));
  ref.listen<double>(appFontScaleProvider, (_, s) => db.setSetting(_fontScaleKey, s.toStringAsFixed(2)));
}
