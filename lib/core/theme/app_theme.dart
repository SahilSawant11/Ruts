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
      cardColor: AppColors.background,
      textTheme: TextTheme(
        headlineSmall: AppTypography.h1,
        titleMedium: AppTypography.h2,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.bodyMuted,
        labelSmall: AppTypography.label,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.textPrimary),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
        textStyle: AppTypography.body.copyWith(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        dividerColor: AppColors.border,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.background,
        dialHandColor: AppColors.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.shellDark,
        contentTextStyle: AppTypography.body.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AppTypography.body.copyWith(color: AppColors.textPrimary),
        menuStyle: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.background),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.border,
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
      cardColor: AppColors.surfaceDark,
      textTheme: TextTheme(
        headlineSmall: AppTypography.h1.copyWith(color: AppColors.textPrimaryDark),
        titleMedium: AppTypography.h2.copyWith(color: AppColors.textPrimaryDark),
        bodyMedium: AppTypography.body.copyWith(color: AppColors.textPrimaryDark),
        bodySmall: AppTypography.bodyMuted.copyWith(color: AppColors.textSecondaryDark),
        labelSmall: AppTypography.label.copyWith(color: AppColors.textMutedDark),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        titleTextStyle: AppTypography.h2.copyWith(color: AppColors.textPrimaryDark),
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.textPrimaryDark),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        textStyle: AppTypography.body.copyWith(color: AppColors.textPrimaryDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimaryDark,
        iconColor: AppColors.textSecondaryDark,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryDark,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        dividerColor: AppColors.borderDark,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return AppColors.textMutedDark;
          return AppColors.textPrimaryDark;
        }),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return AppColors.textMutedDark;
          return AppColors.textPrimaryDark;
        }),
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.surfaceDark,
        hourMinuteTextColor: AppColors.textPrimaryDark,
        hourMinuteColor: AppColors.surfaceAltDark,
        dialBackgroundColor: AppColors.surfaceAltDark,
        dialTextColor: AppColors.textPrimaryDark,
        dialHandColor: AppColors.primary,
        entryModeIconColor: AppColors.textSecondaryDark,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceAltDark,
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.textPrimaryDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AppTypography.body.copyWith(color: AppColors.textPrimaryDark),
        menuStyle: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surfaceDark),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.borderDark,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.borderDark,
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
