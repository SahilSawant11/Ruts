import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/dashboard_providers.dart';

class DailyTargetCard extends ConsumerWidget {
  const DailyTargetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Daily Target'),
          const SizedBox(height: AppSpacing.md),
          summaryAsync.when(
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => SizedBox(
              height: 80,
              child: Center(child: Text('Could not load target.', style: AppTypography.bodyMuted)),
            ),
            data: (summary) {
              final progress = summary.dailyTarget > 0 ? (summary.todaySales / summary.dailyTarget).clamp(0.0, 1.0) : 0.0;
              final remaining = (summary.dailyTarget - summary.todaySales).clamp(0, double.infinity);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('₹${summary.todaySales.toStringAsFixed(0)}', style: AppTypography.h1),
                      const SizedBox(width: 6),
                      Text('/ ₹${summary.dailyTarget.toStringAsFixed(0)}', style: AppTypography.bodyMuted),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceAltFor(context),
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% achieved · ₹${remaining.toStringAsFixed(0)} to target',
                    style: AppTypography.bodyMuted.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
