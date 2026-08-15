import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../cart_controller.dart';

/// Right-column summary card: line-by-line totals with the grand
/// total called out in a dark highlight band. All figures are derived
/// live from the cart — nothing here is hardcoded.
class BillSummaryCard extends ConsumerWidget {
  const BillSummaryCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);

    String money(double v) => v.toStringAsFixed(0);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: SectionHeader(title: 'Bill Summary', icon: Icons.receipt_outlined),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                _SummaryRow(label: 'Total Qty', value: '${cart.totalQty}', compact: compact),
                _SummaryRow(label: 'Taxable Value', value: money(cart.taxableValue), compact: compact),
                _SummaryRow(label: 'Total Discount', value: money(cart.totalDiscount), compact: compact),
                _SummaryRow(label: 'Total Tax', value: money(cart.totalTax), compact: compact),
              ],
            ),
          ),
          SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: compact ? AppSpacing.xs : AppSpacing.sm,
            ),
            color: AppColors.totalSurfaceFor(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount',
                    style: AppTypography.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(money(cart.totalAmount), style: AppTypography.h2.copyWith(color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: compact ? AppSpacing.xs : AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance Due',
                  style: AppTypography.bodyMuted.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
                Text(money(cart.totalAmount),
                    style: AppTypography.body.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700)),
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
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMuted.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}
