import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../domain/sale_line_item.dart';
import '../cart_controller.dart';

/// "Item Details" table: one row per scanned product, sourced live from
/// [cartControllerProvider]. Empty-state prompts the user toward the
/// barcode field above instead of showing a bare table.
class ItemDetailsTable extends ConsumerWidget {
  const ItemDetailsTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final items = cart.items;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Item Details',
            subtitle: items.isEmpty ? 'No items yet' : '${items.length} line · ${cart.totalQty} units',
          ),
          const SizedBox(height: AppSpacing.sm),
          if (items.isEmpty)
            _emptyState()
          else ...[
            _headerRow(),
            const Divider(height: 1, color: AppColors.border),
            for (var i = 0; i < items.length; i++) _dataRow(context, ref, i, items[i]),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Scan a barcode above to add a line · click the trash icon to remove one',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.qr_code_scanner_rounded, size: 28, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.xs),
            Text('Scan or type a barcode to start this bill', style: AppTypography.bodyMuted),
          ],
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _cell('#', flex: 1, header: true),
          _cell('BARCODE', flex: 2, header: true),
          _cell('TYPE', flex: 1, header: true),
          _cell('MATERIAL', flex: 3, header: true),
          _cell('BATCH', flex: 1, header: true),
          _cell('PACK', flex: 1, header: true),
          _cell('QTY', flex: 1, header: true, alignEnd: true),
          _cell('RATE', flex: 1, header: true, alignEnd: true),
          _cell('DIS', flex: 1, header: true, alignEnd: true),
          _cell('TAX', flex: 1, header: true, alignEnd: true),
          _cell('AMOUNT', flex: 2, header: true, alignEnd: true),
          _cell('', flex: 1, header: true),
        ],
      ),
    );
  }

  Widget _dataRow(BuildContext context, WidgetRef ref, int index, SaleLineItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _cell('${item.index}', flex: 1),
          _cell(item.barcode, flex: 2),
          _cell(item.type, flex: 1),
          _cell(item.material, flex: 3, bold: true),
          _cell(item.batch, flex: 1),
          _cell(item.pack, flex: 1),
          _cell('${item.qty}', flex: 1, alignEnd: true),
          _cell(item.rate.toStringAsFixed(0), flex: 1, alignEnd: true),
          _cell(item.discountAmount.toStringAsFixed(0), flex: 1, alignEnd: true),
          _cell(item.taxAmount.toStringAsFixed(0), flex: 1, alignEnd: true),
          _cell(item.amount.toStringAsFixed(0), flex: 2, alignEnd: true, bold: true),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.check_circle_rounded, size: 17, color: AppColors.success),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => ref.read(cartControllerProvider.notifier).removeAt(index),
                  child: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.danger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, {required int flex, bool header = false, bool alignEnd = false, bool bold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        overflow: TextOverflow.ellipsis,
        style: header
            ? AppTypography.label
            : AppTypography.body.copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
      ),
    );
  }
}
