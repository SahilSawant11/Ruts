import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

enum StatusChipTone { success, neutral, dark }

/// Chip with a colored status dot, e.g. "Online", "Scanner Ready", "Live".
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusChipTone.success,
    this.icon,
  });

  final String label;
  final StatusChipTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = tone == StatusChipTone.dark;
    final dotColor = tone == StatusChipTone.neutral
        ? AppColors.textMutedFor(context)
        : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.backgroundFor(context),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark ? AppColors.shellBorderFor(context) : AppColors.borderFor(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.70)
                  : AppColors.textSecondaryFor(context),
            ),
            const SizedBox(width: 6),
          ] else ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: AppTypography.bodyMuted.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.70)
                  : AppColors.textSecondaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}
