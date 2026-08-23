import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/inventory_filters_card.dart';
import '../widgets/inventory_story_card.dart';
import '../widgets/live_stock_table.dart';
import '../widgets/sku_category_card.dart';
import '../widgets/stock_health_card.dart';
import '../widgets/stock_reorder_card.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory',
            style: AppTypography.h1.copyWith(
              color: AppColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Shelf health, format mix, and restock signals in one place.',
            style: AppTypography.bodyMuted.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const InventoryStoryCard(),
          const SizedBox(height: AppSpacing.lg),
          const InventoryFiltersCard(),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: StockHealthCard()),
              SizedBox(width: AppSpacing.lg),
              Expanded(child: SkuCategoryCard()),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: LiveStockTable(
                  title: 'Live Shelf View',
                  subtitle: 'Packaging + category markers for fast operator scanning',
                  maxTableHeight: 460,
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(child: StockReorderCard()),
            ],
          ),
        ],
      ),
    );
  }
}
