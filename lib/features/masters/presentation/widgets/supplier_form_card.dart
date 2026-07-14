import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class SupplierFormCard extends StatelessWidget {
  const SupplierFormCard({super.key});

  static const _selectIcon = Icon(Icons.unfold_more_rounded, size: 16, color: AppColors.textMuted);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Supplier Information', subtitle: 'Supplier No. auto-assigned'),
          const SizedBox(height: AppSpacing.md),
          _row(const [
            AppTextField(label: 'SUPPLIER NO.', hint: '1007', enabled: false),
            AppTextField(label: 'NAME *', hint: 'J.R.TOLARAM'),
            AppTextField(label: 'DIS %', hint: '2.5'),
          ], flexes: const [2, 7, 3]),
          const SizedBox(height: AppSpacing.md),
          const AppTextField(label: 'ADDRESS', hint: '77, Dock Road, Masjid Bunder, Mumbai - 400009'),
          const SizedBox(height: AppSpacing.md),
          _row(const [
            AppTextField(label: 'CONTACT NO.', hint: '+91 98200 11223'),
            AppTextField(label: 'EMAIL', hint: 'accounts@jrtolaram.com'),
            AppTextField(label: 'VAT NO.', hint: '27AAACJ1234A1Z2'),
          ], flexes: const [3, 4, 3]),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                flex: 5,
                child: AppTextField(label: 'BANK DETAILS', hint: 'HDFC Bank · A/c 0001234567 · IFSC HDFC0000123'),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(flex: 3, child: AppTextField(label: 'OPENING BALANCE', hint: '84,500')),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 4,
                child: AppTextField(label: 'BALANCE TYPE', hint: 'Credit (Dr)', suffix: _selectIcon),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SecondaryButton(label: 'Modify', icon: Icons.edit_outlined, onPressed: () {}),
              DangerButton(label: 'Delete', icon: Icons.delete_outline_rounded, onPressed: () {}),
              SecondaryButton(label: 'View', icon: Icons.visibility_outlined, onPressed: () {}),
              SecondaryButton(label: 'Prev', icon: Icons.chevron_left_rounded, onPressed: () {}),
              SecondaryButton(label: 'Next', icon: Icons.chevron_right_rounded, onPressed: () {}),
              PrimaryButton(label: 'Save', icon: Icons.save_outlined, onPressed: () {}),
              SecondaryButton(label: 'Close', icon: Icons.close_rounded, onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<Widget> fields, {List<int>? flexes}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(flex: flexes?[i] ?? 1, child: fields[i]),
        ],
      ],
    );
  }
}
