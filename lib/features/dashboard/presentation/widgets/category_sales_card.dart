import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/charts/category_bar_row.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/dashboard_providers.dart';

class CategorySalesCard extends ConsumerWidget {
  const CategorySalesCard({super.key});

  static const _palette = [
    AppColors.primary,
    AppColors.chartIndigo,
    AppColors.chartBlue,
    AppColors.chartTeal,
    AppColors.chartAmber,
    AppColors.success,
  ];

  String _formatAmount(double amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(0)}k';
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Sales by Category', subtitle: 'Last 30 days'),
          const SizedBox(height: 4),
          summaryAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'Could not load categories.',
                  style: AppTypography.bodyMuted.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
            ),
            data: (summary) {
              final breakdown = summary.categoryBreakdown;
              if (breakdown.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'No sales in the last 30 days.',
                      style: AppTypography.bodyMuted.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ),
                );
              }
              final maxAmount = breakdown.map((c) => c.amount).reduce((a, b) => a > b ? a : b);
              return Column(
                children: [
                  for (var i = 0; i < breakdown.length; i++)
                    CategoryBarRow(
                      label: breakdown[i].category,
                      valueLabel: _formatAmount(breakdown[i].amount),
                      fraction: maxAmount > 0 ? breakdown[i].amount / maxAmount : 0,
                      color: _palette[i % _palette.length],
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
