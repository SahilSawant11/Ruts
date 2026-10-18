import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/inventory_kpi_strip.dart';
import '../widgets/live_stock_table.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Full desktop viewport: Sticky header table layout
        if (constraints.maxHeight > 550) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InventoryKpiStrip(),
                SizedBox(height: AppSpacing.md),
                Expanded(
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
