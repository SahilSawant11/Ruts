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
}
