import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../badges/keyboard_shortcut_badge.dart';

/// The global "Type here to search..." field with a Ctrl K badge.
class SearchField extends StatelessWidget {
  const SearchField({super.key, this.width = 300});

  final double width;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.textMutedFor(context);
    return SizedBox(
      width: width,
      child: TextField(
        style: AppTypography.body,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Icon(Icons.search, size: 19, color: muted),
          hintText: 'Type here to search...',
          hintStyle: AppTypography.bodyMuted.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
          suffixIcon: const Padding(
            padding: EdgeInsets.only(right: AppSpacing.xs),
            child: Align(
              alignment: Alignment.center,
              widthFactor: 1,
              child: KeyboardShortcutBadge(label: 'Ctrl K', onLight: true),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: AppColors.glassSurfaceStrongFor(context),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide(color: AppColors.glassBorderFor(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide(color: AppColors.glassBorderFor(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
          ),
        ),
      ),
    );
  }
}
