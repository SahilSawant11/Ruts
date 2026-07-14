import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/charts/category_bar_row.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class SkuCategoryCard extends StatelessWidget {
  const SkuCategoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(title: 'SKUs by Category'),
          SizedBox(height: 4),
          CategoryBarRow(label: 'Whisky', valueLabel: '128', fraction: 0.92, color: AppColors.primary),
          CategoryBarRow(label: 'Beer', valueLabel: '96', fraction: 0.69, color: AppColors.chartIndigo),
          CategoryBarRow(label: 'Wine', valueLabel: '74', fraction: 0.53, color: AppColors.chartBlue),
          CategoryBarRow(label: 'Rum', valueLabel: '58', fraction: 0.42, color: AppColors.chartTeal),
          CategoryBarRow(label: 'Vodka', valueLabel: '41', fraction: 0.30, color: AppColors.chartAmber),
          CategoryBarRow(label: 'Soft Drink', valueLabel: '89', fraction: 0.64, color: AppColors.success),
        ],
      ),
    );
  }
}
