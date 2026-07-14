import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// One row: fixed-width label, a filled track, then a value — all on
/// a single line. Used by "Sales by Category" and "SKUs by Category".
class CategoryBarRow extends StatelessWidget {
  const CategoryBarRow({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.fraction,
    required this.color,
    this.labelWidth = 90,
  });

  final String label;
  final String valueLabel;
  final double fraction;
  final Color color;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: fraction.clamp(0, 1),
                minHeight: 10,
                backgroundColor: AppColors.surfaceAlt,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 50,
            child: Text(
              valueLabel,
              textAlign: TextAlign.right,
              style: AppTypography.mono.copyWith(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
