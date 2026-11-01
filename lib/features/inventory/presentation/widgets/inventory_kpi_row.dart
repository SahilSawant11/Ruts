import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/data/kpi_card.dart';
import '../../data/inventory_providers.dart';

class InventoryKpiRow extends ConsumerWidget {
  const InventoryKpiRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(filteredInventoryOverviewProvider);

    return overviewAsync.when(
      loading: () => const _KpiSkeletonRow(),
      error: (_, __) => const _KpiSkeletonRow(),
      data: (items) {
        final inStock = items.where((i) => i.isInStock).length;
        final lowStock = items.where((i) => i.isLowStock).length;
        final outOfStock = items.where((i) => i.isOutOfStock).length;

        return Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Total Items',
                value: '${items.length}',
                icon: AppIcons.crate,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KpiCard(
                label: 'Ready to Sell',
                value: '$inStock',
                icon: AppIcons.checkCircle,
                trendText: items.isEmpty ? null : '${(inStock / items.length * 100).round()}% of items',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KpiCard(
                label: 'Low Stock',
                value: '$lowStock',
                icon: AppIcons.warning,
                tone: KpiTone.amber,
                trendText: lowStock == 0 ? null : 'needs reorder soon',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KpiCard(
                label: 'Out of Stock',
                value: '$outOfStock',
                icon: AppIcons.cartRemove,
                tone: KpiTone.red,
                trendText: outOfStock == 0 ? null : 'reorder needed',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiSkeletonRow extends StatelessWidget {
  const _KpiSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: KpiCard(label: 'Total Items', value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Ready to Sell', value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Low Stock', value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Out of Stock', value: '—')),
      ],
    );
  }
}
