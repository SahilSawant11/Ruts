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
///  - Sales & Purchase line chart on ink, full width
///  - Top categories + top selling products
///  - Recent transactions
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
    // Chart height grows with the Text size setting.
    final rowHeight = 300 + 120 * MediaQuery.textScalerOf(context).scale(1);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Wheat field: the period's sales + four fact cards
          const DashboardHero(),
          const SizedBox(height: AppSpacing.lg),

          // 2. Sales & Purchase line chart (ink)
          SizedBox(height: rowHeight, child: const SalesPurchaseLineCard()),
          const SizedBox(height: AppSpacing.lg),

          // 3. Top categories + top selling products
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: TopCategoriesCard()),
              SizedBox(width: AppSpacing.lg),
              Expanded(child: TopSellingProductsCard()),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. Recent transactions
          const RecentTransactionsCard(),
          const SizedBox(height: AppSpacing.lg),

          // 5. Yearly activity heatmap
          const TransactionActivityHeatmapCard(),
        ],
      ),
    );
  }
}
