import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class DailyTargetCard extends StatelessWidget {
  const DailyTargetCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Daily Target', subtitle: '28-Jun-2026'),
          const SizedBox(height: AppSpacing.md),
          RichText(
            text: TextSpan(
              style: AppTypography.h1.copyWith(fontSize: 26),
              children: [
                const TextSpan(text: '₹1,84,920'),
                TextSpan(text: ' / ₹2,50,000', style: AppTypography.bodyMuted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: const LinearProgressIndicator(
              value: 0.74,
              minHeight: 10,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text('74% achieved', style: AppTypography.body.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
              Text(' · ₹65,080 to target', style: AppTypography.bodyMuted),
            ],
          ),
        ],
      ),
    );
  }
}
