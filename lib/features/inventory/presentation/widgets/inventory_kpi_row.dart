import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/data/kpi_card.dart';
import '../../data/inventory_providers.dart';

class InventoryKpiRow extends ConsumerWidget {
  const InventoryKpiRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(inventoryOverviewProvider);

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
              child: KpiCard(label: 'Total SKUs', value: '${items.length}', icon: Icons.inventory_2_outlined),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KpiCard(
                label: 'In Stock',
                value: '$inStock',
                icon: Icons.check_circle_outline_rounded,
                trendText: items.isEmpty ? null : '${(inStock / items.length * 100).round()}% of catalog',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KpiCard(
                label: 'Low Stock',
                value: '$lowStock',
                icon: Icons.warning_amber_rounded,
                tone: KpiTone.amber,
                trendText: lowStock == 0 ? null : 'needs reorder soon',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KpiCard(
                label: 'Out of Stock',
                value: '$outOfStock',
                icon: Icons.remove_shopping_cart_outlined,
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
        Expanded(child: KpiCard(label: 'Total SKUs', value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'In Stock', value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Low Stock', value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Out of Stock', value: '—')),
      ],
    );
  }
}
