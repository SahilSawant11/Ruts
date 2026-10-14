import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/category_sales_card.dart';
import '../widgets/daily_target_card.dart';
import '../widgets/kpi_row.dart';
import '../widgets/payment_mix_card.dart';
import '../widgets/recent_transactions_card.dart';
import '../widgets/sales_trend_card.dart';
import '../widgets/stock_alerts_card.dart';
import '../widgets/transaction_activity_heatmap_card.dart';
import '../widgets/top_customers_card.dart';
import '../widgets/top_selling_items_card.dart';

/// Widget tree:
/// AppShell
///   └── DashboardScreen body
///         └── SingleChildScrollView → Column
///               ├── DashboardKpiRow (4 KPI cards, real data)
///               ├── Row: SalesTrendCard | CategorySalesCard
///               ├── Row: PaymentMixCard | DailyTargetCard
///               ├── Row: TopSellingItemsCard | RecentTransactionsCard
///               ├── TopCustomersCard
///               └── StockAlertsCard
///               └── TransactionActivityHeatmapCard
///
/// All widgets read from dashboardSummaryProvider (one API call) or
/// inventoryOverviewProvider (shared with the Inventory screen).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardKpiRow(),
          SizedBox(height: AppSpacing.lg),
          _TwoColumn(left: SalesTrendCard(), right: CategorySalesCard()),
          _TwoColumn(left: PaymentMixCard(), right: DailyTargetCard()),
          _TwoColumn(left: TopSellingItemsCard(), right: RecentTransactionsCard()),
          TopCustomersCard(),
          SizedBox(height: AppSpacing.lg),
          StockAlertsCard(),
          SizedBox(height: AppSpacing.lg),
          TransactionActivityHeatmapCard(),
        ],
      ),
    );
  }
}

/// Two cards side by side with a fixed gutter, stacked below `_DashboardHeader`.
class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: right),
        ],
      ),
    );
  }
}
