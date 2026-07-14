import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class InventoryFiltersCard extends StatelessWidget {
  const InventoryFiltersCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Filters'),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Expanded(child: AppTextField(label: 'CATEGORY', hint: 'All categories')),
              SizedBox(width: AppSpacing.md),
              Expanded(child: AppTextField(label: 'STATUS', hint: 'All')),
              SizedBox(width: AppSpacing.md),
              Expanded(child: AppTextField(label: 'SUPPLIER', hint: 'All suppliers')),
              SizedBox(width: AppSpacing.md),
              Expanded(child: AppTextField(label: 'SEARCH SKU', hint: 'Barcode or name')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SecondaryButton(label: 'Stock Transfer', icon: Icons.compare_arrows_rounded, onPressed: () {}),
              const SizedBox(width: AppSpacing.sm),
              SecondaryButton(label: 'Stock Adjustment', icon: Icons.tune_rounded, onPressed: () {}),
              const Spacer(),
              PrimaryButton(label: 'Add Stock', icon: Icons.add_rounded, onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}
