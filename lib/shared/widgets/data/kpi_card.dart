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

  Color _iconBg(BuildContext context) {
    switch (tone) {
      case KpiTone.amber:
        return AppColors.isDark(context)
            ? AppColors.warning.withValues(alpha: 0.16)
            : AppColors.warningSoft;
      case KpiTone.red:
        return AppColors.isDark(context)
            ? AppColors.danger.withValues(alpha: 0.16)
            : AppColors.dangerSoft;
      case KpiTone.normal:
        return AppColors.isDark(context)
            ? AppColors.primary.withValues(alpha: 0.16)
            : AppColors.primarySoft;
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
              Text(
                label.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
              if (icon != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _iconBg(context).withValues(
                      alpha: AppColors.isDark(context) ? 1 : 0.88,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.isDark(context)
                          ? AppColors.borderFor(context)
                          : Colors.white.withValues(alpha: 0.55),
                    ),
                    boxShadow: AppColors.cardShadowFor(context)
                        .map((shadow) => BoxShadow(
                              color: shadow.color.withValues(alpha: shadow.color.a * 0.28),
                              blurRadius: shadow.blurRadius * 0.34,
                              offset: shadow.offset * 0.18,
                            ))
                        .toList(),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 18, color: _iconColor),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.h1.copyWith(
              fontSize: 29,
              height: 1.05,
              color: AppColors.textPrimaryFor(context),
            ),
          ),
          if (trendText != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  trendText!,
                  style: AppTypography.bodyMuted.copyWith(
                    fontWeight: FontWeight.w700,
                    color: trendUp == null
                        ? AppColors.textSecondaryFor(context)
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
                backgroundColor: AppColors.surfaceAltFor(context),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            if (progressCaption != null) ...[
              const SizedBox(height: 6),
              Text(
                progressCaption!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
