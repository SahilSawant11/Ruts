import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../domain/purchase_line_item.dart';

/// Purchase "Item Details" table. Has more columns than the Sales
/// table, so it scrolls horizontally with fixed column widths instead
/// of flexing — keeps every figure aligned and readable.
class PurchaseItemTable extends StatelessWidget {
  const PurchaseItemTable({super.key});

  static const _columns = <(String, double, bool)>[
    ('#', 32, false),
    ('MATERIAL', 220, false),
    ('BATCH NO.', 90, false),
    ('PACKING', 90, false),
    ('KG', 55, true),
    ('RATE', 65, true),
    ('DISPER', 60, true),
    ('DIS', 60, true),
    ('PER', 55, false),
    ('TAX%', 50, true),
    ('TAXAMT', 65, true),
    ('AMOUNT', 75, true),
    ('TOTAMT', 75, true),
    ('UNITS', 70, false),
    ('ACTIONS', 100, false),
  ];

  @override
  Widget build(BuildContext context) {
    final items = PurchaseLineItem.dummy();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Item Details', subtitle: 'KG / case units per batch'),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerRow(),
                const Divider(height: 1, color: AppColors.border),
                for (final item in items) _dataRow(item),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _addLineButton(),
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
              child: Text(
                col.$1,
                textAlign: col.$3 ? TextAlign.right : TextAlign.left,
                style: AppTypography.label,
              ),
            ),
        ],
      ),
    );
  }

  Widget _dataRow(PurchaseLineItem item) {
    final values = <String>[
      '${item.index}',
      item.material,
      item.batch,
      item.packing,
      '${item.kg}',
      item.rate.toStringAsFixed(0),
      item.discountPercent.toStringAsFixed(0),
      item.discount.toStringAsFixed(0),
      item.per,
      item.taxPercent.toStringAsFixed(0),
      item.taxAmount.toStringAsFixed(0),
      item.amount.toStringAsFixed(0),
      item.totalAmount.toStringAsFixed(0),
      item.units,
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
                      children: const [
                        Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                        SizedBox(width: 6),
                        Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                        SizedBox(width: 6),
                        Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                      ],
                    )
                  : Text(
                      values[i],
                      textAlign: _columns[i].$3 ? TextAlign.right : TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      style: i == 1
                          ? AppTypography.body.copyWith(fontWeight: FontWeight.w700)
                          : AppTypography.body,
                    ),
            ),
        ],
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
            SizedBox(width: AppSpacing.md),
            Text('F10 — Delete batch line', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}
