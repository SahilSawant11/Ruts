import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/dashboard_providers.dart';
import '../widgets/dashboard_hero.dart';
import '../widgets/recent_transactions_card.dart';
import '../widgets/sales_purchase_line_card.dart';
import '../widgets/top_categories_card.dart';
import '../widgets/top_selling_products_card.dart';
import '../widgets/transaction_activity_heatmap_card.dart';

/// Dashboard in the flat card system:
///  - Gold field: period sales (big figure) + purchases / returns / low stock / products
///  - Sales & Purchase chart on ink + top categories
///  - Top selling products + recent transactions
///  - Yearly activity heatmap
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
          // 1. Gold field: the period's sales + four fact cards
          DashboardHero(),
          SizedBox(height: AppSpacing.lg),

          // 2. Sales & Purchase chart (ink) + top categories
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: SalesPurchaseLineCard()),
              SizedBox(width: AppSpacing.lg),
              Expanded(flex: 5, child: TopCategoriesCard()),
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
