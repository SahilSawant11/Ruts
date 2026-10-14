import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
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
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InventoryStoryCard(),
          SizedBox(height: AppSpacing.lg),
          InventoryFiltersCard(),
          SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: StockHealthCard()),
              SizedBox(width: AppSpacing.lg),
              Expanded(child: SkuCategoryCard()),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
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
