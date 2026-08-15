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
    final inventoryAsync = ref.watch(inventoryListProvider);

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
                onPressed: () => ref.invalidate(inventoryListProvider),
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
                    child: Text('No stock yet — save a Purchase Bill to see it here.', style: AppTypography.bodyMuted),
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
                        '${items.length} item${items.length == 1 ? '' : 's'} tracked live',
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
          _iconHeaderCell(context),
          _cell(context, 'BARCODE', flex: 2, header: true),
          _cell(context, 'MATERIAL', flex: 4, header: true),
          _cell(context, 'CATEGORY', flex: 2, header: true),
          _cell(context, 'QTY ON HAND', flex: 2, header: true, alignEnd: true),
          _cell(context, 'REORDER AT', flex: 2, header: true, alignEnd: true),
          _cell(context, 'STATUS', flex: 2, header: true),
        ],
      ),
    );
  }

  Widget _dataRow(BuildContext context, InventoryItemDto item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _iconCell(context, item.packing),
          _cell(context, item.barcode, flex: 2, mono: true),
          _cell(context, item.name, flex: 4, bold: true),
          _cell(context, item.category, flex: 2),
          _cell(context, '${item.qtyOnHand}', flex: 2, alignEnd: true, bold: true),
          _cell(context, '${item.reorderLevel}', flex: 2, alignEnd: true),
          Expanded(flex: 2, child: _statusPill(item)),
        ],
      ),
    );
  }

  Widget _iconHeaderCell(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Text(
        'TYPE',
        style: AppTypography.label.copyWith(
          color: AppColors.textMutedFor(context),
        ),
      ),
    );
  }

  Widget _iconCell(BuildContext context, String packing) {
    final config = _packingIconFor(packing);
    return SizedBox(
      width: 40,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: config.background,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.borderFor(context),
            ),
          ),
          child: Icon(
            config.icon,
            size: 16,
            color: config.foreground,
          ),
        ),
      ),
    );
  }

  _PackingIconConfig _packingIconFor(String packing) {
    final normalized = packing.toLowerCase();
    if (normalized.contains('can')) {
      return _PackingIconConfig(
        icon: Icons.local_drink_outlined,
        foreground: AppColors.chartBlue,
        background: AppColors.chartBlue.withValues(alpha: 0.14),
      );
    }
    return const _PackingIconConfig(
      icon: Icons.wine_bar_outlined,
      foreground: AppColors.primary,
      background: AppColors.primarySoft,
    );
  }

  Widget _statusPill(InventoryItemDto item) {
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

class _PackingIconConfig {
  const _PackingIconConfig({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
}
