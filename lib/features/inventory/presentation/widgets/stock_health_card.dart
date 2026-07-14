import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/charts/donut_chart.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class StockHealthCard extends StatelessWidget {
  const StockHealthCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Stock Health'),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: DonutChart(
              centerValue: '486',
              centerLabel: 'total SKUs',
              segments: const [
                DonutSegment(value: 441, color: AppColors.success),
                DonutSegment(value: 32, color: AppColors.warning),
                DonutSegment(value: 13, color: AppColors.danger),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _legendRow('In Stock', '441', AppColors.success),
          _legendRow('Low Stock', '32', AppColors.warning),
          _legendRow('Out of Stock', '13', AppColors.danger),
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
