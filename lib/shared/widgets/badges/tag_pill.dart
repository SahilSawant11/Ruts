import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

enum TagPillTone { neutral, success, amber, danger }

/// Small colored pill for inline statuses (Paid/Credit) or category
/// tags (Beer/Whisky) inside tables and lists.
class TagPill extends StatelessWidget {
  const TagPill({super.key, required this.label, this.tone = TagPillTone.neutral});

  final String label;
  final TagPillTone tone;

  ({Color bg, Color fg}) _colors(BuildContext context) {
    switch (tone) {
      case TagPillTone.success:
        return (
          bg: AppColors.isDark(context)
              ? AppColors.success.withValues(alpha: 0.16)
              : AppColors.successSoft,
          fg: AppColors.success,
        );
      case TagPillTone.amber:
        return (
          bg: AppColors.isDark(context)
              ? AppColors.warning.withValues(alpha: 0.16)
              : AppColors.warningSoft,
          fg: AppColors.warning,
        );
      case TagPillTone.danger:
        return (
          bg: AppColors.isDark(context)
              ? AppColors.danger.withValues(alpha: 0.16)
              : AppColors.dangerSoft,
          fg: AppColors.danger,
        );
      case TagPillTone.neutral:
        return (
          bg: AppColors.surfaceAltFor(context),
          fg: AppColors.textSecondaryFor(context),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 4),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: c.fg, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}
