import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/data/kpi_card.dart';

class InventoryKpiRow extends StatelessWidget {
  const InventoryKpiRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: KpiCard(label: 'Total SKUs', value: '486', icon: Icons.inventory_2_outlined),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: KpiCard(
            label: 'In Stock',
            value: '441',
            icon: Icons.check_circle_outline_rounded,
            trendText: '91% of catalog',
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: KpiCard(
            label: 'Low Stock',
            value: '32',
            icon: Icons.warning_amber_rounded,
            tone: KpiTone.amber,
            trendText: 'needs reorder soon',
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: KpiCard(
            label: 'Out of Stock',
            value: '13',
            icon: Icons.remove_shopping_cart_outlined,
            tone: KpiTone.red,
            trendText: 'reorder today',
          ),
        ),
      ],
    );
  }
}
