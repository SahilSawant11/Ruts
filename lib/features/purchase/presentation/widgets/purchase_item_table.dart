import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../domain/purchase_line_item.dart';
import '../purchase_cart_controller.dart';
import 'add_material_line_dialog.dart';

/// Purchase "Item Details" table, sourced live from
/// [purchaseCartControllerProvider]. Has more columns than the Sales
/// table, so it scrolls horizontally with fixed column widths instead
/// of flexing — keeps every figure aligned and readable.
class PurchaseItemTable extends ConsumerWidget {
  const PurchaseItemTable({super.key, this.expand = false});

  static const _columns = <(String, double, bool)>[
    ('#', 32, false),
    ('MATERIAL', 220, false),
    ('BATCH NO.', 90, false),
    ('PACKING', 90, false),
    ('QTY', 55, true),
    ('RATE', 65, true),
    ('DISPER', 60, true),
    ('DIS', 60, true),
    ('TAX%', 50, true),
    ('TAXAMT', 65, true),
    ('AMOUNT', 75, true),
    ('ACTIONS', 90, false),
  ];
  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(purchaseCartControllerProvider);
    final items = cart.items;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compressed = expand && constraints.maxHeight < 220;
        final tableBody = items.isEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(
                  vertical: compressed ? AppSpacing.sm : AppSpacing.lg,
                ),
                child: Center(
                  child: Text(
                    'Add a material line to start this purchase bill',
                    style: AppTypography.bodyMuted,
                  ),
                ),
              )
            : SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headerRow(),
                      Divider(height: 1, color: AppColors.borderFor(context)),
                      for (var i = 0; i < items.length; i++) _dataRow(context, ref, i, items[i]),
                    ],
                  ),
                ),
              );

        return AppCard(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            compressed ? AppSpacing.sm : AppSpacing.md,
            AppSpacing.md,
            compressed ? AppSpacing.xs : AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Item Details',
                subtitle: compressed
                    ? null
                    : items.isEmpty
                        ? 'No lines yet'
                        : '${items.length} line(s) · batch units per line',
                trailing: compressed ? _addLineButton(context, compact: true) : null,
              ),
              SizedBox(height: compressed ? AppSpacing.xs : AppSpacing.sm),
              if (expand) Expanded(child: tableBody) else tableBody,
              if (!compressed) ...[
                const SizedBox(height: AppSpacing.xs),
                _addLineButton(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _headerRow() {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            for (final col in _columns)
              SizedBox(
                width: col.$2,
                child: Text(
                  col.$1,
                  textAlign: col.$3 ? TextAlign.right : TextAlign.left,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textMutedFor(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dataRow(BuildContext context, WidgetRef ref, int index, PurchaseLineItem item) {
    final values = <String>[
      '${item.index}',
      item.material,
      item.batch,
      item.packing,
      '${item.qty}',
      item.rate.toStringAsFixed(0),
      item.discountPercent.toStringAsFixed(0),
      item.discountAmount.toStringAsFixed(0),
      item.taxPercent.toStringAsFixed(0),
      item.taxAmount.toStringAsFixed(0),
      item.amount.toStringAsFixed(0),
      '',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < _columns.length; i++)
            SizedBox(
              width: _columns[i].$2,
              child: i == _columns.length - 1
                  ? Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => ref.read(purchaseCartControllerProvider.notifier).removeAt(index),
                          child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                        ),
                      ],
                    )
                  : Text(
                      values[i],
                      textAlign: _columns[i].$3 ? TextAlign.right : TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      style: (i == 1 ? AppTypography.body.copyWith(fontWeight: FontWeight.w700) : AppTypography.body)
                          .copyWith(color: AppColors.textPrimaryFor(context)),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _addLineButton(BuildContext context, {bool compact = false}) {
    return InkWell(
      onTap: () => showAddMaterialLineDialog(context),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 2 : 8),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
            SizedBox(width: 6),
            Text(
              'Add line',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
