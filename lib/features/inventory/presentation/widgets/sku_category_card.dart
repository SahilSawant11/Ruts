import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/charts/category_bar_row.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/inventory_providers.dart';

class SkuCategoryCard extends ConsumerWidget {
  const SkuCategoryCard({super.key});

  static const _palette = [
    AppColors.primary,
    AppColors.chartIndigo,
    AppColors.chartBlue,
    AppColors.chartTeal,
    AppColors.chartAmber,
    AppColors.success,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(inventoryOverviewProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'SKUs by Category'),
          const SizedBox(height: 4),
          overviewAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: Text('Could not load categories.', style: AppTypography.bodyMuted)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: Text('No materials yet.', style: AppTypography.bodyMuted)),
                );
              }

              final counts = <String, int>{};
              for (final item in items) {
                counts[item.category] = (counts[item.category] ?? 0) + 1;
              }
              final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
              final maxCount = sorted.first.value;

              return Column(
                children: [
                  for (var i = 0; i < sorted.length; i++)
                    CategoryBarRow(
                      label: sorted[i].key,
                      valueLabel: '${sorted[i].value}',
                      fraction: sorted[i].value / maxCount,
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
