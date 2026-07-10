import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized text styles. Screens should pull from here, not
/// call GoogleFonts directly, so the whole app stays consistent.
class AppTypography {
  AppTypography._();

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMuted => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.4,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get sidebarSection => GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: AppColors.shellTextMuted,
        letterSpacing: 0.8,
      );

  static TextStyle get sidebarItem => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      );
}
