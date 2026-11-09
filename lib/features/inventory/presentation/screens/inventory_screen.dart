import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/category_bottle_gauges.dart';
import '../widgets/inventory_kpi_strip.dart';
import '../widgets/live_stock_table.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Full desktop viewport: sticky header table layout. The category
        // bottles only show when there is room left for a useful table.
        if (constraints.maxHeight > 550) {
          final showGauges = constraints.maxHeight >= 640;
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const InventoryKpiStrip(),
                if (showGauges) ...[
                  const SizedBox(height: AppSpacing.md),
                  const CategoryBottleGauges(),
                ],
                const SizedBox(height: AppSpacing.md),
                const Expanded(
                  child: LiveStockTable(),
                ),
              ],
            ),
          );
        }

        // Small height fallback
        return const SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InventoryKpiStrip(),
              SizedBox(height: AppSpacing.md),
              CategoryBottleGauges(),
              SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 480,
                child: LiveStockTable(),
              ),
            ],
          ),
        );
      },
    );
  }
}
