import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/tag_pill.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/inventory_providers.dart';
import '../../data/models/inventory_item_dto.dart';

/// The one genuinely live piece of the Inventory screen right now —
/// reads straight from GET /api/inventory, which reflects real
/// Purchase (+stock) and Sales (-stock) activity. The KPI row and
/// charts above this table are still illustrative placeholders.
class LiveStockTable extends ConsumerWidget {
  const LiveStockTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryListProvider);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Live Stock',
                  subtitle: 'Real quantities from Purchase + Sales activity',
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => ref.invalidate(inventoryListProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          inventoryAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text('Could not load inventory: $error', style: AppTypography.bodyMuted),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text('No stock yet — save a Purchase Bill to see it here.', style: AppTypography.bodyMuted),
                  ),
                );
              }
              return Column(
                children: [
                  _headerRow(),
                  const Divider(height: 1, color: AppColors.border),
                  for (final item in items) _dataRow(item),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _cell('BARCODE', flex: 2, header: true),
          _cell('MATERIAL', flex: 4, header: true),
          _cell('CATEGORY', flex: 2, header: true),
          _cell('QTY ON HAND', flex: 2, header: true, alignEnd: true),
          _cell('REORDER AT', flex: 2, header: true, alignEnd: true),
          _cell('STATUS', flex: 2, header: true),
        ],
      ),
    );
  }

  Widget _dataRow(InventoryItemDto item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _cell(item.barcode, flex: 2, mono: true),
          _cell(item.name, flex: 4, bold: true),
          _cell(item.category, flex: 2),
          _cell('${item.qtyOnHand}', flex: 2, alignEnd: true, bold: true),
          _cell('${item.reorderLevel}', flex: 2, alignEnd: true),
          Expanded(flex: 2, child: _statusPill(item)),
        ],
      ),
    );
  }

  Widget _statusPill(InventoryItemDto item) {
    if (item.isOutOfStock) return const TagPill(label: 'OUT OF STOCK', tone: TagPillTone.danger);
    if (item.isLowStock) return const TagPill(label: 'LOW STOCK', tone: TagPillTone.amber);
    return const TagPill(label: 'IN STOCK', tone: TagPillTone.success);
  }

  Widget _cell(
    String text, {
    required int flex,
    bool header = false,
    bool alignEnd = false,
    bool bold = false,
    bool mono = false,
  }) {
    final style = header
        ? AppTypography.label
        : mono
            ? AppTypography.mono.copyWith(fontSize: 12, color: AppColors.textSecondary)
            : AppTypography.body.copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w500);

    return Expanded(
      flex: flex,
      child: Text(text, textAlign: alignEnd ? TextAlign.end : TextAlign.start, overflow: TextOverflow.ellipsis, style: style),
    );
  }
}
