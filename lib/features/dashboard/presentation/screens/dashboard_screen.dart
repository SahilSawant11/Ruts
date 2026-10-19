import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/dashboard_providers.dart';
import '../widgets/kpi_row.dart';
import '../widgets/overall_information_card.dart';
import '../widgets/recent_transactions_card.dart';
import '../widgets/sales_purchase_capsule_card.dart';
import '../widgets/top_categories_card.dart';
import '../widgets/top_selling_products_card.dart';
import '../widgets/transaction_activity_heatmap_card.dart';

/// Complete Dashboard Screen matching the mood board design:
///  - 4 Elevated KPI Cards (Total Sales, Sales Return, Total Purchase, Purchase Return)
///  - Middle Grid: Sales & Purchase Side-by-Side Capsule Chart (flex 7) + Overall Info & Top Categories Stack (flex 5)
///  - Bottom Grid: Top Selling Products (1/2) + Recent Transactions Mini Table (1/2)
///  - Collapsible / anchored Transaction Activity Heatmap
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(dashboardSummaryProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top 4 Elevated KPI Cards (with synchronized uniform timeframe)
          DashboardKpiRow(),
          SizedBox(height: AppSpacing.lg),

          // 2. Middle Grid: Sales & Purchase Chart + Overall Info & Top Categories Stack
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: SalesPurchaseCapsuleCard(),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    OverallInformationCard(),
                    SizedBox(height: AppSpacing.md),
                    TopCategoriesCard(),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),

          // 4. Bottom Grid: Top Selling Products + Recent Transactions Table
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TopSellingProductsCard(),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: RecentTransactionsCard(),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),

          // 5. Yearly Activity Heatmap
          TransactionActivityHeatmapCard(),
        ],
      ),
    );
  }
}
