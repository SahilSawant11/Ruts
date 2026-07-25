import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/tag_pill.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../../inventory/data/inventory_providers.dart';
import '../../../inventory/data/models/inventory_overview_item.dart';

/// Reuses inventoryOverviewProvider from the Inventory feature rather
/// than duplicating the low/out-of-stock logic here — same source of
/// truth as the Inventory screen's own KPIs.
class StockAlertsCard extends ConsumerWidget {
  const StockAlertsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(inventoryOverviewProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Stock Alerts'),
          const SizedBox(height: 4),
          overviewAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: Text('Could not load stock.', style: AppTypography.bodyMuted)),
            ),
            data: (items) {
              final atRisk = items.where((i) => i.isLowStock || i.isOutOfStock).toList()
                ..sort((a, b) => a.qtyOnHand.compareTo(b.qtyOnHand));

              if (atRisk.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: Text('Everything is well-stocked.', style: AppTypography.bodyMuted)),
                );
              }
              return Column(
                children: [for (final item in atRisk.take(6)) _row(item)],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _row(InventoryOverviewItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                Text('${item.qtyOnHand} left · reorder at ${item.reorderLevel}', style: AppTypography.caption),
              ],
            ),
          ),
          TagPill(
            label: item.isOutOfStock ? 'OUT' : 'LOW',
            tone: item.isOutOfStock ? TagPillTone.danger : TagPillTone.amber,
          ),
        ],
      ),
    );
  }
}
