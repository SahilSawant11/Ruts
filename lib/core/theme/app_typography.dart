import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized text styles. Screens should pull from here, not
/// call GoogleFonts directly, so the whole app stays consistent.
class AppTypography {
  AppTypography._();

  /// Current global brightness tracking, kept synced with MaterialApp's active theme.
  static Brightness currentBrightness = Brightness.light;
  static bool get isDark => currentBrightness == Brightness.dark;

  static Color get _textPrimary =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  static Color get _textSecondary =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
  static Color get _textMuted =>
      isDark ? AppColors.textMutedDark : AppColors.textMuted;

  static TextStyle get h1 => GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
        height: 1.15,
      );

  static TextStyle get h2 => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
        height: 1.2,
      );

  static TextStyle get sectionTitle => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
        height: 1.2,
      );

  static TextStyle get body => GoogleFonts.manrope(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: _textPrimary,
        height: 1.35,
      );

  static TextStyle get bodyMuted => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: _textSecondary,
        height: 1.35,
      );

  static TextStyle get bodySmallMuted => bodyMuted;

  static TextStyle get label => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _textMuted,
        letterSpacing: 0.45,
        height: 1.2,
      );

  static TextStyle get caption => GoogleFonts.manrope(
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
        color: _textMuted,
        height: 1.3,
      );

  static TextStyle get captionMuted => caption;

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      );

  static TextStyle get sidebarSection => GoogleFonts.manrope(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: AppColors.shellTextMuted,
        letterSpacing: 0.9,
        height: 1.2,
      );

  static TextStyle get sidebarItem => GoogleFonts.manrope(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        height: 1.25,
      );

  // Context-aware getters
  static TextStyle h1For(BuildContext context) =>
      h1.copyWith(color: AppColors.textPrimaryFor(context));
  static TextStyle h2For(BuildContext context) =>
      h2.copyWith(color: AppColors.textPrimaryFor(context));
  static TextStyle sectionTitleFor(BuildContext context) =>
      sectionTitle.copyWith(color: AppColors.textPrimaryFor(context));
  static TextStyle bodyFor(BuildContext context) =>
      body.copyWith(color: AppColors.textPrimaryFor(context));
  static TextStyle bodyMutedFor(BuildContext context) =>
      bodyMuted.copyWith(color: AppColors.textSecondaryFor(context));
  static TextStyle labelFor(BuildContext context) =>
      label.copyWith(color: AppColors.textMutedFor(context));
  static TextStyle captionFor(BuildContext context) =>
      caption.copyWith(color: AppColors.textMutedFor(context));
  static TextStyle monoFor(BuildContext context) =>
      mono.copyWith(color: AppColors.textPrimaryFor(context));
}
