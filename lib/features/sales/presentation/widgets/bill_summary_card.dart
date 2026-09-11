import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../cart_controller.dart';

/// Right-column summary panel: displays breakdown rows and a prominent
/// high-contrast dark Payable Card with the total amount payable,
/// completely wrapped in the app's signature pebble card aesthetic.
class BillSummaryCard extends ConsumerWidget {
  const BillSummaryCard({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);

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
                  const Icon(Icons.receipt_outlined, size: 16, color: AppColors.primary),
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
                  '${cart.items.length} items',
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
              _summaryRow('Total Qty', '${cart.totalQty}', context),
              _summaryRow('Taxable Amount', '₹${cart.taxableValue.toStringAsFixed(2)}', context),
              _summaryRow('Total Tax', '₹${cart.totalTax.toStringAsFixed(2)}', context),
              _summaryRow('Discount', '₹${cart.totalDiscount.toStringAsFixed(2)}', context),

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
                        color: AppColors.textMutedDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₹${cart.totalAmount.toStringAsFixed(2)}',
                      style: AppTypography.mono.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              // Balance Due Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Balance Due',
                      style: AppTypography.bodyMuted.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                    Text(
                      '₹${cart.totalAmount.toStringAsFixed(2)}',
                      style: AppTypography.mono.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: cart.totalAmount > 0 ? AppColors.danger : AppColors.success,
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
