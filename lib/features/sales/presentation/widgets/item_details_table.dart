import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../domain/sale_line_item.dart';

/// "Item Details" table: one row per scanned product. Dummy data only —
/// wiring to Drift + a real Add-line flow comes in a later pass.
class ItemDetailsTable extends StatelessWidget {
  const ItemDetailsTable({super.key});

  static const _headers = [
    '#',
    'BARCODE',
    'TYPE',
    'MATERIAL',
    'BATCH',
    'PACK',
    'QTY',
    'RATE',
    'DIS',
    'TAX',
    'AMOUNT',
    '',
  ];

  @override
  Widget build(BuildContext context) {
    final items = SaleLineItem.dummy();
    final totalQty = items.fold<int>(0, (a, b) => a + b.qty);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Item Details',
            subtitle: '${items.length} line · $totalQty units',
          ),
          const SizedBox(height: AppSpacing.sm),
          _headerRow(),
          const Divider(height: 1, color: AppColors.border),
          for (final item in items) _dataRow(item),
          const SizedBox(height: AppSpacing.xs),
          _addLineButton(),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter adds a new line · F10 deletes the highlighted line',
            style: AppTypography.caption,
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

  Widget _dataRow(SaleLineItem item) {
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
          _cell(item.discount.toStringAsFixed(0), flex: 1, alignEnd: true),
          _cell(item.tax.toStringAsFixed(0), flex: 1, alignEnd: true),
          _cell(item.amount.toStringAsFixed(0), flex: 2, alignEnd: true, bold: true),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Icon(Icons.check_circle_rounded, size: 17, color: AppColors.success),
                SizedBox(width: 8),
                Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.danger),
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

  Widget _addLineButton() {
    return InkWell(
      onTap: () {},
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
