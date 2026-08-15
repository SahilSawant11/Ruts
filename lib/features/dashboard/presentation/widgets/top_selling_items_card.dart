import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/data/info_list_tile.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/dashboard_providers.dart';

class TopSellingItemsCard extends ConsumerWidget {
  const TopSellingItemsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Top Selling Items', subtitle: 'Last 30 days, by units sold'),
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
                  'Could not load top items.',
                  style: AppTypography.bodyMuted.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
            ),
            data: (summary) {
              if (summary.topSellingItems.isEmpty) {
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
              return Column(
                children: [
                  for (final item in summary.topSellingItems)
                    InfoListTile(
                      icon: Icons.local_bar_outlined,
                      title: item.materialName,
                      subtitle: item.packing ?? '${item.qty} units sold',
                      trailing: '₹${item.amount.toStringAsFixed(0)}',
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
