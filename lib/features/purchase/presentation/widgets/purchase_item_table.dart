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
  const PurchaseItemTable({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(purchaseCartControllerProvider);
    final items = cart.items;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Item Details',
            subtitle: items.isEmpty ? 'No lines yet' : '${items.length} line(s) · batch units per line',
          ),
          const SizedBox(height: AppSpacing.sm),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: Text('Add a material line to start this purchase bill', style: AppTypography.bodyMuted)),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerRow(),
                  const Divider(height: 1, color: AppColors.border),
                  for (var i = 0; i < items.length; i++) _dataRow(ref, i, items[i]),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          _addLineButton(context),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          for (final col in _columns)
            SizedBox(
              width: col.$2,
              child: Text(col.$1, textAlign: col.$3 ? TextAlign.right : TextAlign.left, style: AppTypography.label),
            ),
        ],
      ),
    );
  }

  Widget _dataRow(WidgetRef ref, int index, PurchaseLineItem item) {
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
                      style: i == 1 ? AppTypography.body.copyWith(fontWeight: FontWeight.w700) : AppTypography.body,
                    ),
            ),
        ],
      ),
    );
  }

  Widget _addLineButton(BuildContext context) {
    return InkWell(
      onTap: () => showAddMaterialLineDialog(context),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
            SizedBox(width: 6),
            Text('Add line', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
