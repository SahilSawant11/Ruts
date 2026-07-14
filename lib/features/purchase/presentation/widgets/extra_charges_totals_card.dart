import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class ExtraChargesTotalsCard extends StatelessWidget {
  const ExtraChargesTotalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: SectionHeader(title: 'Extra Charges & Totals'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: const [
                Expanded(child: AppTextField(label: 'DISCOUNT', hint: '0')),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: AppTextField(label: 'VAT', hint: '0')),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: AppTextField(label: 'STAMP', hint: '25')),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: AppTextField(label: 'TCS', hint: '0')),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: AppTextField(label: 'LOADING / FREIGHT', hint: '350')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Net Amount', style: AppTypography.bodyMuted),
                Text('5,528', style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            color: AppColors.totalDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount', style: AppTypography.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('5,528', style: AppTypography.h1.copyWith(color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SecondaryButton(label: 'Modify', icon: Icons.edit_outlined, onPressed: () {}),
                SecondaryButton(label: 'View', icon: Icons.visibility_outlined, onPressed: () {}),
                DangerButton(label: 'Delete', icon: Icons.delete_outline_rounded, onPressed: () {}),
                SecondaryButton(label: 'Payments', icon: Icons.account_balance_wallet_outlined, onPressed: () {}),
                PrimaryButton(label: 'Save', icon: Icons.save_outlined, onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
