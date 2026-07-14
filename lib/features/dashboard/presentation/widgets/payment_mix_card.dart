import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/charts/labeled_progress_row.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class PaymentMixCard extends StatelessWidget {
  const PaymentMixCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Payment Mix', subtitle: 'Today'),
          const SizedBox(height: 6),
          const LabeledProgressRow(label: 'Cash', valueLabel: '₹98,400 · 53%', fraction: 0.53, color: AppColors.primary),
          const LabeledProgressRow(label: 'Card', valueLabel: '₹52,300 · 28%', fraction: 0.28, color: AppColors.chartBlue),
          const LabeledProgressRow(label: 'UPI', valueLabel: '₹28,900 · 16%', fraction: 0.16, color: AppColors.chartTeal),
          const LabeledProgressRow(label: 'Credit', valueLabel: '₹5,320 · 3%', fraction: 0.03, color: AppColors.chartAmber),
        ],
      ),
    );
  }
}
