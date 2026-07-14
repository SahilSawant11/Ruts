import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/charts/reorder_bar_chart.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class StockReorderCard extends StatelessWidget {
  const StockReorderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Stock Level vs Reorder',
            subtitle: 'Top SKUs closest to their reorder threshold',
          ),
          const SizedBox(height: 12),
          const ReorderBarChart(
            data: [
              ReorderBarData(label: 'London Pilsener 500ml', value: 12, color: AppColors.danger),
              ReorderBarData(label: 'Kingfisher Strong 650ml', value: 18, color: AppColors.warning),
              ReorderBarData(label: 'Budweiser Magnum', value: 24, color: AppColors.warning),
              ReorderBarData(label: 'Carlsberg Smooth', value: 45, color: AppColors.success),
              ReorderBarData(label: 'Jack Daniels 750ml', value: 8, color: AppColors.danger),
              ReorderBarData(label: 'Absolut Vodka 1L', value: 52, color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }
}
