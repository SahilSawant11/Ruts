import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/tag_pill.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/inventory_providers.dart';
import '../../data/models/inventory_overview_item.dart';
import 'inventory_item_profile.dart';

/// Real stock table backed by the merged inventory overview so it
/// respects category/status/search filters while still reflecting
/// purchase and sales activity offline.
class LiveStockTable extends ConsumerWidget {
  const LiveStockTable({
    super.key,
    this.title = 'Live Bottles & Cans',
    this.subtitle = 'Real quantities from Purchase + Sales activity',
    this.maxTableHeight,
  });

  final String title;
  final String subtitle;
  final double? maxTableHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(filteredInventoryOverviewProvider);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionHeader(
                  title: title,
                  subtitle: subtitle,
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => ref.invalidate(inventoryOverviewProvider),
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.textSecondaryFor(context),
                ),
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
                    child: Text('No inventory items match the current filters.', style: AppTypography.bodyMuted),
                  ),
                );
              }
              final sortedItems = [...items]
                ..sort((a, b) {
                  final aRank = a.isOutOfStock ? 0 : (a.isLowStock ? 1 : 2);
                  final bRank = b.isOutOfStock ? 0 : (b.isLowStock ? 1 : 2);
                  final rankCompare = aRank.compareTo(bRank);
                  if (rankCompare != 0) return rankCompare;
                  return a.qtyOnHand.compareTo(b.qtyOnHand);
                });

              final table = Column(
                children: [
                  _headerRow(context),
                  Divider(height: 1, color: AppColors.borderFor(context)),
                  for (final item in sortedItems) _dataRow(context, item),
                ],
              );

              return Column(
                children: [
                  if (maxTableHeight != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxTableHeight!),
                      child: SingleChildScrollView(child: table),
                    )
                  else
                    table,
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(
                        '${items.length} item${items.length == 1 ? '' : 's'} shown',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryFor(context),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Low + out of stock float to the top',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMutedFor(context),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _headerRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _profileHeaderCell(context),
          _cell(context, 'ITEM', flex: 4, header: true),
          _cell(context, 'ON HAND', flex: 2, header: true, alignEnd: true),
          _cell(context, 'REORDER', flex: 2, header: true, alignEnd: true),
          _cell(context, 'STATUS', flex: 2, header: true),
        ],
      ),
    );
  }

  Widget _dataRow(BuildContext context, InventoryOverviewItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _profileCell(context, item),
          _itemCell(context, item),
          _cell(context, '${item.qtyOnHand}', flex: 2, alignEnd: true, bold: true),
          _cell(context, '${item.reorderLevel}', flex: 2, alignEnd: true),
          Expanded(flex: 2, child: _statusPill(item)),
        ],
      ),
    );
  }

  Widget _profileHeaderCell(BuildContext context) {
    return SizedBox(
      width: 126,
      child: Text(
        'PROFILE',
        style: AppTypography.label.copyWith(
          color: AppColors.textMutedFor(context),
        ),
      ),
    );
  }

  Widget _profileCell(BuildContext context, InventoryOverviewItem item) {
    return SizedBox(
      width: 126,
      child: Row(
        children: [
          InventoryItemProfile(
            item: item,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.manufacturer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.category} · ${item.packing}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCell(BuildContext context, InventoryOverviewItem item) {
    return Expanded(
      flex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${item.materialId} · ${item.barcode}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.mono.copyWith(
              fontSize: 11,
              color: AppColors.textMutedFor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(InventoryOverviewItem item) {
    if (item.isOutOfStock) return const TagPill(label: 'OUT OF STOCK', tone: TagPillTone.danger);
    if (item.isLowStock) return const TagPill(label: 'LOW STOCK', tone: TagPillTone.amber);
    return const TagPill(label: 'IN STOCK', tone: TagPillTone.success);
  }

  Widget _cell(
    BuildContext context,
    String text, {
    required int flex,
    bool header = false,
    bool alignEnd = false,
    bool bold = false,
    bool mono = false,
  }) {
    final style = header
        ? AppTypography.label.copyWith(
            color: AppColors.textMutedFor(context),
          )
        : mono
            ? AppTypography.mono.copyWith(
                fontSize: 12,
                color: AppColors.textSecondaryFor(context),
              )
            : AppTypography.body.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textPrimaryFor(context),
              );

    return Expanded(
      flex: flex,
      child: Text(text, textAlign: alignEnd ? TextAlign.end : TextAlign.start, overflow: TextOverflow.ellipsis, style: style),
    );
  }
}
