import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: AppTypography.body.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        surface: AppColors.background,
        error: AppColors.danger,
      ),
      dividerColor: AppColors.border,
      cardColor: Colors.white.withValues(alpha: 0.86),
      textTheme: TextTheme(
        headlineSmall: AppTypography.h1,
        titleMedium: AppTypography.h2,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.bodyMuted,
        labelSmall: AppTypography.label,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.86),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: AppTypography.body.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        surface: AppColors.surfaceDark,
        error: AppColors.danger,
      ).copyWith(
        onPrimary: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimaryDark,
        secondary: AppColors.chartBlue,
        outline: AppColors.borderDark,
      ),
      dividerColor: AppColors.borderDark,
      cardColor: Colors.white.withValues(alpha: 0.08),
      textTheme: TextTheme(
        headlineSmall: AppTypography.h1.copyWith(color: AppColors.textPrimaryDark),
        titleMedium: AppTypography.h2.copyWith(color: AppColors.textPrimaryDark),
        bodyMedium: AppTypography.body.copyWith(color: AppColors.textPrimaryDark),
        bodySmall: AppTypography.bodyMuted.copyWith(color: AppColors.textSecondaryDark),
        labelSmall: AppTypography.label.copyWith(color: AppColors.textMutedDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
