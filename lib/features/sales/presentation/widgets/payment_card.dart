import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../sales_providers.dart';

/// Payment method selector + the primary checkout actions
/// (Save & Print, Print Preview, Hold, Close/Clear).
class PaymentCard extends ConsumerWidget {
  const PaymentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = ref.watch(paymentMethodProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Payment', icon: Icons.account_balance_wallet_outlined),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _methodTile(
                  ref: ref,
                  label: 'Cash',
                  icon: Icons.payments_outlined,
                  method: PaymentMethod.cash,
                  selected: method == PaymentMethod.cash,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _methodTile(
                  ref: ref,
                  label: 'Card',
                  icon: Icons.credit_card_outlined,
                  method: PaymentMethod.card,
                  selected: method == PaymentMethod.card,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _methodTile(
                  ref: ref,
                  label: 'UPI',
                  icon: Icons.qr_code_2_rounded,
                  method: PaymentMethod.upi,
                  selected: method == PaymentMethod.upi,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('3,402', style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: AppSpacing.md),
          SuccessButton(
            label: 'Save & Print',
            shortcut: 'F8',
            icon: Icons.print_outlined,
            expand: true,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Print Preview',
                  icon: Icons.visibility_outlined,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SecondaryButton(
                  label: 'Hold',
                  icon: Icons.pause_circle_outline_rounded,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DangerButton(
            label: 'Close / Clear',
            icon: Icons.close_rounded,
            expand: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _methodTile({
    required WidgetRef ref,
    required String label,
    required IconData icon,
    required PaymentMethod method,
    required bool selected,
  }) {
    return InkWell(
      onTap: () => ref.read(paymentMethodProvider.notifier).state = method,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 19, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.bodyMuted.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
