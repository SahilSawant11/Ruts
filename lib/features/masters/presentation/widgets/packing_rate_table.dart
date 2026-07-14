import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../domain/material_packing.dart';

class PackingRateTable extends StatelessWidget {
  const PackingRateTable({super.key});

  static const _columns = <(String, int, bool)>[
    ('#', 1, false),
    ('PACKING', 2, false),
    ('ITEM CODE', 2, false),
    ('PUR RATE', 1, true),
    ('SALE RATE', 1, true),
    ('WHOLESALE', 1, true),
    ('QTY', 1, true),
    ('BARCODE', 2, false),
    ('ACTIONS', 2, false),
  ];

  @override
  Widget build(BuildContext context) {
    final rows = MaterialPacking.dummy();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Packing / Rate List', subtitle: 'Purchase, wholesale & sale rates per pack'),
          const SizedBox(height: AppSpacing.sm),
          _headerRow(),
          const Divider(height: 1, color: AppColors.border),
          for (final row in rows) _dataRow(row),
          const SizedBox(height: AppSpacing.xs),
          _addPackingButton(),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SecondaryButton(label: 'Modify', icon: Icons.edit_outlined, onPressed: () {}),
              SecondaryButton(label: 'View', icon: Icons.visibility_outlined, onPressed: () {}),
              DangerButton(label: 'Delete', icon: Icons.delete_outline_rounded, onPressed: () {}),
              PrimaryButton(label: 'Save', icon: Icons.save_outlined, onPressed: () {}),
              SecondaryButton(label: 'Close', icon: Icons.close_rounded, onPressed: () {}),
            ],
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
          for (final col in _columns)
            Expanded(
              flex: col.$2,
              child: Text(col.$1, textAlign: col.$3 ? TextAlign.right : TextAlign.left, style: AppTypography.label),
            ),
        ],
      ),
    );
  }

  Widget _dataRow(MaterialPacking row) {
    final values = [
      '${row.index}',
      row.packing,
      row.itemCode,
      row.purRate.toStringAsFixed(0),
      row.saleRate.toStringAsFixed(0),
      row.wholesale.toStringAsFixed(0),
      '${row.qty}',
      row.barcode,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              flex: _columns[i].$2,
              child: Text(
                values[i],
                textAlign: _columns[i].$3 ? TextAlign.right : TextAlign.left,
                overflow: TextOverflow.ellipsis,
                style: i == 1 ? AppTypography.body.copyWith(fontWeight: FontWeight.w700) : AppTypography.body,
              ),
            ),
          Expanded(
            flex: _columns.last.$2,
            child: Row(
              children: const [
                Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                SizedBox(width: 8),
                Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                SizedBox(width: 8),
                Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Icon(Icons.visibility_outlined, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addPackingButton() {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
            SizedBox(width: 6),
            Text('Add packing', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
