import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/data/kpi_card.dart';

class DashboardKpiRow extends StatelessWidget {
  const DashboardKpiRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: KpiCard(
            label: "Today's Sales",
            value: '₹1,84,920',
            icon: Icons.shopping_cart_outlined,
            trendText: '▲ 12.4% vs yesterday',
            trendUp: true,
            progress: 0.74,
            progressCaption: '74% of ₹2.5L daily target',
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: KpiCard(
            label: 'Bills',
            value: '312',
            icon: Icons.receipt_long_outlined,
            trendText: '▲ 8% vs yesterday',
            trendUp: true,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: KpiCard(
            label: 'Avg Bill Value',
            value: '₹592',
            icon: Icons.account_balance_wallet_outlined,
            trendText: '▼ 2.1% vs yesterday',
            trendUp: false,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: KpiCard(
            label: 'Low Stock Items',
            value: '3',
            icon: Icons.warning_amber_rounded,
            trendText: 'needs reorder today',
            tone: KpiTone.amber,
          ),
        ),
      ],
    );
  }
}
