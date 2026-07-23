import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/charts/reorder_bar_chart.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/inventory_providers.dart';
import '../../data/models/inventory_overview_item.dart';

class StockReorderCard extends ConsumerWidget {
  const StockReorderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(inventoryOverviewProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Stock Level vs Reorder',
            subtitle: 'Materials closest to (or below) their reorder threshold',
          ),
          const SizedBox(height: 12),
          overviewAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: Text('Could not load stock data.', style: AppTypography.bodyMuted)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: Text('No materials yet.', style: AppTypography.bodyMuted)),
                );
              }

              // Sort by how far below/above reorder level each item is —
              // most at-risk (lowest qty relative to its threshold) first.
              final sorted = [...items]
                ..sort((a, b) => (a.qtyOnHand - a.reorderLevel).compareTo(b.qtyOnHand - b.reorderLevel));
              final topSix = sorted.take(6).toList();

              return ReorderBarChart(
                data: [
                  for (final item in topSix)
                    ReorderBarData(
                      label: item.name,
                      value: item.qtyOnHand,
                      color: _colorFor(item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _colorFor(InventoryOverviewItem item) {
    if (item.isOutOfStock) return AppColors.danger;
    if (item.isLowStock) return AppColors.warning;
    return AppColors.success;
  }
}
