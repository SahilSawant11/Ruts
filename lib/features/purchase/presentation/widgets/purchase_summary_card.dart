import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../purchase_cart_controller.dart';
import '../purchase_form_controller.dart';

/// Right-column summary panel for Purchase: displays breakdown rows and a
/// prominent high-contrast dark Payable Card with the total inward amount,
/// styled in the app's signature pebble card aesthetic.
class PurchaseSummaryCard extends ConsumerWidget {
  const PurchaseSummaryCard({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(purchaseCartControllerProvider);
    final form = ref.watch(purchaseFormControllerProvider);

    final lineCount = cart.items.length;
    final totalQty = cart.items.fold<int>(0, (sum, i) => sum + i.qty);
    final itemsAmount = cart.itemsAmount;
    final extraCharges = form.extraCharges;
    final netAmount = itemsAmount + extraCharges;

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
                  '$lineCount line${lineCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Summary Metrics
          _SummaryRow(label: 'Line Items', value: '$lineCount'),
          const SizedBox(height: AppSpacing.xs),
          _SummaryRow(label: 'Total Units', value: '$totalQty'),
          const SizedBox(height: AppSpacing.xs),
          _SummaryRow(label: 'Gross Items Total', value: '₹${itemsAmount.toStringAsFixed(2)}'),
          const SizedBox(height: AppSpacing.xs),
          _SummaryRow(
            label: 'Extra Charges / Adjustments',
            value: '${extraCharges >= 0 ? '+' : '-'}₹${extraCharges.abs().toStringAsFixed(2)}',
            valueColor: extraCharges > 0
                ? AppColors.warning
                : (extraCharges < 0 ? AppColors.success : null),
          ),
          const SizedBox(height: AppSpacing.xs),
          _SummaryRow(
            label: 'Net Taxable Value',
            value: '₹${netAmount.toStringAsFixed(2)}',
            isBold: true,
          ),

          const SizedBox(height: AppSpacing.md),

          // Total Amount Banner (high-contrast pebble block)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.totalSurfaceFor(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL PAYABLE',
                      style: AppTypography.label.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 9.5,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gross + charges',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${netAmount.toStringAsFixed(2)}',
                  style: AppTypography.mono.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryFor(context),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTypography.mono.copyWith(
            fontSize: isBold ? 13 : 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? AppColors.textPrimaryFor(context),
          ),
        ),
      ],
    );
  }
}
