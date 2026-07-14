import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/charts/category_bar_row.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class CategorySalesCard extends StatelessWidget {
  const CategorySalesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Sales by Category'),
          const SizedBox(height: 4),
          const CategoryBarRow(label: 'Whisky', valueLabel: '₹79k', fraction: 0.86, color: AppColors.primary),
          const CategoryBarRow(label: 'Beer', valueLabel: '₹59k', fraction: 0.64, color: AppColors.chartIndigo),
          const CategoryBarRow(label: 'Wine', valueLabel: '₹35k', fraction: 0.38, color: AppColors.chartBlue),
          const CategoryBarRow(label: 'Rum', valueLabel: '₹27k', fraction: 0.30, color: AppColors.chartTeal),
          const CategoryBarRow(label: 'Vodka', valueLabel: '₹16k', fraction: 0.18, color: AppColors.chartAmber),
        ],
      ),
    );
  }
}
