import 'package:flutter/material.dart';

/// Centralized color tokens.
/// Never hardcode a Color(...) inside a widget — add it here first.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF5A46D6);
  static const Color primarySoft = Color(0xFFEFECFE);

  // Status
  static const Color success = Color(0xFF12A150);
  static const Color successSoft = Color(0xFFE7F8EE);
  static const Color danger = Color(0xFFE0393E);
  static const Color dangerSoft = Color(0xFFFBEAEA);
  static const Color warning = Color(0xFFF5A524);
  static const Color warningSoft = Color(0xFFFEF3E2);
  static const Color info = Color(0xFF3B82F6);

  // Neutrals - light theme
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F7FA);
  static const Color surfaceAlt = Color(0xFFF1F1F6);
  static const Color border = Color(0xFFE6E6EE);
  static const Color borderStrong = Color(0xFFD8D8E4);

  // Text
  static const Color textPrimary = Color(0xFF16161F);
  static const Color textSecondary = Color(0xFF6B6B7B);
  static const Color textMuted = Color(0xFF9B9BAC);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Dark theme neutrals
  static const Color backgroundDark = Color(0xFF12141B);
  static const Color surfaceDark = Color(0xFF191C24);
  static const Color surfaceAltDark = Color(0xFF232735);
  static const Color borderDark = Color(0xFF313748);
  static const Color borderStrongDark = Color(0xFF454D63);
  static const Color textPrimaryDark = Color(0xFFF4F5F8);
  static const Color textSecondaryDark = Color(0xFFB6BDD0);
  static const Color textMutedDark = Color(0xFF8189A0);

  // Sidebar / status bar (dark shell around the light workspace)
  static const Color shellDark = Color(0xFF121219);
  static const Color shellDarkAlt = Color(0xFF1B1B26);
  static const Color shellBorder = Color(0xFF2A2A38);
  static const Color shellTextMuted = Color(0xFF9494A6);

  // Chart accents
  static const Color chartIndigo = Color(0xFF6366F1);
  static const Color chartBlue = Color(0xFF0EA5E9);
  static const Color chartTeal = Color(0xFF14B8A6);
  static const Color chartAmber = Color(0xFFF59E0B);

  // Highlight for totals
  static const Color totalDark = Color(0xFF15151F);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundFor(BuildContext context) =>
      isDark(context) ? backgroundDark : background;

  static Color surfaceFor(BuildContext context) =>
      isDark(context) ? surfaceDark : surface;

  static Color surfaceAltFor(BuildContext context) =>
      isDark(context) ? surfaceAltDark : surfaceAlt;

  static Color borderFor(BuildContext context) =>
      isDark(context) ? borderDark : border;

  static Color borderStrongFor(BuildContext context) =>
      isDark(context) ? borderStrongDark : borderStrong;

  static Color textPrimaryFor(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimary;

  static Color textSecondaryFor(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondary;

  static Color textMutedFor(BuildContext context) =>
      isDark(context) ? textMutedDark : textMuted;

  static Color shellBackgroundFor(BuildContext context) =>
      isDark(context) ? shellDarkAlt : shellDark;

  static Color shellBorderFor(BuildContext context) =>
      isDark(context) ? shellBorder : border;

  static Color shellTextMutedFor(BuildContext context) =>
      isDark(context) ? shellTextMuted : textSecondary;

  static Color totalSurfaceFor(BuildContext context) =>
      isDark(context) ? backgroundDark : totalDark;
}
