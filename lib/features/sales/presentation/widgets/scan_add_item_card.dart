import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/layout/app_card.dart';

/// Primary data-entry panel: scan/type a barcode, hit Add, or tap a
/// quick category chip to filter/jump to that department.
class ScanAddItemCard extends StatelessWidget {
  const ScanAddItemCard({super.key});

  static const _categories = ['Whisky', 'Beer', 'Wine', 'Rum', 'Vodka', 'Soft Drink'];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Scan / Add Item',
            subtitle: 'Primary action — scanner auto-focuses on load',
            trailing: StatusChip(label: 'Scanner Ready'),
          ),
          const SizedBox(height: AppSpacing.md),
          _scanRow(),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _categories.map(_categoryChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _scanRow() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.qr_code_scanner_rounded, size: 17, color: Colors.white),
                SizedBox(width: 6),
                Text('BARCODE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Scan barcode or type item code, then press Enter.',
              style: AppTypography.bodyMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          PrimaryButton(label: '+ Add', onPressed: () {}, icon: Icons.add_rounded),
        ],
      ),
    );
  }

  Widget _categoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.bodyMuted.copyWith(fontWeight: FontWeight.w700, fontSize: 11.5),
      ),
    );
  }
}
