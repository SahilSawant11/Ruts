import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized text styles. Screens should pull from here, not
/// call GoogleFonts directly, so the whole app stays consistent.
class AppTypography {
  AppTypography._();

  static TextStyle get h1 => GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.15,
      );

  static TextStyle get h2 => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get sectionTitle => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get body => GoogleFonts.manrope(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get bodyMuted => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.35,
      );

  static TextStyle get label => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.45,
        height: 1.2,
      );

  static TextStyle get caption => GoogleFonts.manrope(
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.3,
      );

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
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
}
