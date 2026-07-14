import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Bold label + value on one line, with a full-width progress track
/// underneath. Used for "Payment Mix" rows.
class LabeledProgressRow extends StatelessWidget {
  const LabeledProgressRow({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.fraction,
    required this.color,
  });

  final String label;
  final String valueLabel;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
              Text(valueLabel, style: AppTypography.bodyMuted),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: 8,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
