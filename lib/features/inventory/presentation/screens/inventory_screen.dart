import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_shell.dart';
import '../widgets/inventory_filters_card.dart';
import '../widgets/inventory_kpi_row.dart';
import '../widgets/live_stock_table.dart';
import '../widgets/sku_category_card.dart';
import '../widgets/stock_health_card.dart';
import '../widgets/stock_reorder_card.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      moduleTitle: 'Inventory',
      moduleShortcutLabel: 'Stock overview',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inventory', style: AppTypography.h1),
            const SizedBox(height: 4),
            Text('Stock levels, reorder points, and category breakdown.', style: AppTypography.bodyMuted),
            const SizedBox(height: AppSpacing.lg),
            const LiveStockTable(),
            const SizedBox(height: AppSpacing.lg),
            const InventoryKpiRow(),
            const SizedBox(height: AppSpacing.lg),
            const InventoryFiltersCard(),
            const SizedBox(height: AppSpacing.lg),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: StockHealthCard()),
                SizedBox(width: AppSpacing.lg),
                Expanded(flex: 2, child: SkuCategoryCard()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const StockReorderCard(),
          ],
        ),
      ),
    );
  }
}
