import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../sales_providers.dart';

/// F2 Purchase Bill / F3 Sales Bill segmented toggle shown just under
/// the screen title.
class BillingModeToggle extends ConsumerWidget {
  const BillingModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(billingModeProvider);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(
            context: context,
            ref: ref,
            label: 'Purchase Bill',
            shortcut: 'F2',
            selected: mode == BillingMode.purchase,
            onTap: () => ref.read(billingModeProvider.notifier).state = BillingMode.purchase,
          ),
          _segment(
            context: context,
            ref: ref,
            label: 'Sales Bill',
            shortcut: 'F3',
            selected: mode == BillingMode.sale,
            onTap: () => ref.read(billingModeProvider.notifier).state = BillingMode.sale,
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required String shortcut,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.background : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      elevation: selected ? 1 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                shortcut,
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
