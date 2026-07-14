import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class MaterialDetailsCard extends StatelessWidget {
  const MaterialDetailsCard({super.key});

  static const _selectIcon = Icon(Icons.unfold_more_rounded, size: 16, color: AppColors.textMuted);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Material Details', subtitle: 'Material No. auto-assigned'),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(flex: 2, child: AppTextField(label: 'MATERIAL NO.', hint: '1024', enabled: false)),
              SizedBox(width: AppSpacing.md),
              Expanded(flex: 7, child: AppTextField(label: 'NAME *', hint: 'London Pilsener Premium Strong Beer')),
              SizedBox(width: AppSpacing.md),
              Expanded(flex: 3, child: AppTextField(label: 'GST %', hint: '5')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 5, child: AppTextField(label: 'MANUFACTURE', hint: 'Uttam Breweries Ltd.')),
              const SizedBox(width: AppSpacing.md),
              Expanded(flex: 4, child: AppTextField(label: 'CATEGORY', hint: 'Beer', suffix: _selectIcon)),
              const SizedBox(width: AppSpacing.md),
              Expanded(flex: 3, child: AppTextField(label: 'TYPE', hint: 'Liquor', suffix: _selectIcon)),
            ],
          ),
        ],
      ),
    );
  }
}
