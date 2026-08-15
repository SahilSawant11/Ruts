import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// F2 Purchase Bill / F3 Sales Bill segmented toggle shown just under
/// the screen title on both the Purchase and Sales screens. Selection
/// follows the current route and tapping navigates to the other one.
class BillingModeToggle extends StatelessWidget {
  const BillingModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isSale = location == '/sales';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderFor(context)),
          ),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _segment(
                context: context,
                label: compact ? 'Purchase' : 'Purchase Bill',
                shortcut: 'F2',
                selected: !isSale,
                onTap: () => context.go('/purchase'),
              ),
              _segment(
                context: context,
                label: compact ? 'Sales' : 'Sales Bill',
                shortcut: 'F3',
                selected: isSale,
                onTap: () => context.go('/sales'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _segment({
    required BuildContext context,
    required String label,
    required String shortcut,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.backgroundFor(context) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      elevation: selected ? 1 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                shortcut,
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: selected ? AppColors.primary : AppColors.textMutedFor(context),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
