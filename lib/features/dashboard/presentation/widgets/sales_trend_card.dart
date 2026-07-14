import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/charts/vertical_bar_chart.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class SalesTrendCard extends StatelessWidget {
  const SalesTrendCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Sales — last 7 days', subtitle: 'Net amount (₹)'),
          const SizedBox(height: 12),
          VerticalBarChart(
            data: const [
              VerticalBarData(label: 'Mon', valueLabel: '1.2L', fraction: 0.55),
              VerticalBarData(label: 'Tue', valueLabel: '1.4L', fraction: 0.64),
              VerticalBarData(label: 'Wed', valueLabel: '1.1L', fraction: 0.50),
              VerticalBarData(label: 'Thu', valueLabel: '1.6L', fraction: 0.74),
              VerticalBarData(label: 'Fri', valueLabel: '1.9L', fraction: 0.88),
              VerticalBarData(label: 'Sat', valueLabel: '2.4L', fraction: 1.0),
              VerticalBarData(label: 'Sun', valueLabel: '1.8L', fraction: 0.82, color: AppColors.chartAmber),
            ],
          ),
        ],
      ),
    );
  }
}
