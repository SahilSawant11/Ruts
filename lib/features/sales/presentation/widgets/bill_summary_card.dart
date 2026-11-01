import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../cart_controller.dart';
import '../../../../core/format/money.dart';

/// Right-column summary panel: displays breakdown rows and a prominent
/// high-contrast dark Payable Card with the total amount payable,
/// completely wrapped in the app's signature pebble card aesthetic.
class BillSummaryCard extends ConsumerWidget {
  const BillSummaryCard({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCount = ref.watch(cartControllerProvider.select((s) => s.items.length));
    final totalQty = ref.watch(cartControllerProvider.select((s) => s.totalQty));
    final taxableValue = ref.watch(cartControllerProvider.select((s) => s.taxableValue));
    final totalTax = ref.watch(cartControllerProvider.select((s) => s.totalTax));
    final totalDiscount = ref.watch(cartControllerProvider.select((s) => s.totalDiscount));
    final totalAmount = ref.watch(cartControllerProvider.select((s) => s.totalAmount));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundFor(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderFor(context)),
        boxShadow: AppColors.cardShadowFor(context),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const AppIcon(AppIcons.receipt, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Bill Summary',
                    style: AppTypography.sectionTitle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryFor(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoftFor(context),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$itemCount items',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
              const SizedBox(height: AppSpacing.sm),

              // Breakdown Rows
              _summaryRow('Total Qty', '$totalQty', context),
              _summaryRow('Taxable Amount', Money.inr(taxableValue), context),
              _summaryRow('Total Tax', Money.inr(totalTax), context),
              _summaryRow('Discount', Money.inr(totalDiscount), context),

              const SizedBox(height: AppSpacing.sm),

              // Pebble Payable Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.totalSurfaceFor(context),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL AMOUNT PAYABLE',
                      style: AppTypography.label.copyWith(
                        fontSize: 9.5,
                        letterSpacing: 0.6,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      Money.inr(totalAmount),
                      style: AppTypography.mono.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        );
  }

  Widget _summaryRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMuted.copyWith(
              fontSize: 11.5,
              color: AppColors.textSecondaryFor(context),
            ),
          ),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}
