import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../layout/app_card.dart';

enum KpiTone { normal, amber, red }

/// Compact stat tile: icon, label, big value, optional trend line and
/// optional inline progress bar with a caption underneath.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trendText,
    this.trendUp,
    this.progress,
    this.progressCaption,
    this.tone = KpiTone.normal,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? trendText;
  final bool? trendUp;
  final double? progress;
  final String? progressCaption;
  final KpiTone tone;

  Color get _iconColor {
    switch (tone) {
      case KpiTone.amber:
        return AppColors.warning;
      case KpiTone.red:
        return AppColors.danger;
      case KpiTone.normal:
        return AppColors.primary;
    }
  }

  Color get _iconBg {
    switch (tone) {
      case KpiTone.amber:
        return AppColors.warningSoft;
      case KpiTone.red:
        return AppColors.dangerSoft;
      case KpiTone.normal:
        return AppColors.primarySoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label.toUpperCase(), style: AppTypography.label),
              if (icon != null)
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(AppRadius.sm)),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 17, color: _iconColor),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.h1.copyWith(fontSize: 26)),
          if (trendText != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  trendText!,
                  style: AppTypography.bodyMuted.copyWith(
                    fontWeight: FontWeight.w700,
                    color: trendUp == null
                        ? AppColors.textSecondary
                        : (trendUp! ? AppColors.success : AppColors.danger),
                  ),
                ),
              ],
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress!.clamp(0, 1),
                minHeight: 6,
                backgroundColor: AppColors.surfaceAlt,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            if (progressCaption != null) ...[
              const SizedBox(height: 6),
              Text(progressCaption!, style: AppTypography.caption),
            ],
          ],
        ],
      ),
    );
  }
}
