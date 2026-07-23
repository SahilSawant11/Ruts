import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/charts/donut_chart.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/inventory_providers.dart';

class StockHealthCard extends ConsumerWidget {
  const StockHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(inventoryOverviewProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Stock Health'),
          const SizedBox(height: AppSpacing.md),
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
              final inStock = items.where((i) => i.isInStock).length;
              final lowStock = items.where((i) => i.isLowStock).length;
              final outOfStock = items.where((i) => i.isOutOfStock).length;

              return Column(
                children: [
                  Center(
                    child: DonutChart(
                      centerValue: '${items.length}',
                      centerLabel: 'total SKUs',
                      segments: [
                        DonutSegment(value: inStock.toDouble(), color: AppColors.success),
                        DonutSegment(value: lowStock.toDouble(), color: AppColors.warning),
                        DonutSegment(value: outOfStock.toDouble(), color: AppColors.danger),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _legendRow('In Stock', '$inStock', AppColors.success),
                  _legendRow('Low Stock', '$lowStock', AppColors.warning),
                  _legendRow('Out of Stock', '$outOfStock', AppColors.danger),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legendRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTypography.bodyMuted)),
          Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
