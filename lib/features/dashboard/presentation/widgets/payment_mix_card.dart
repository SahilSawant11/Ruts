import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/charts/labeled_progress_row.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/dashboard_providers.dart';

class PaymentMixCard extends ConsumerWidget {
  const PaymentMixCard({super.key});

  static const _palette = [AppColors.primary, AppColors.chartBlue, AppColors.chartTeal, AppColors.chartAmber];

  Color _colorFor(String payMode, int index) {
    switch (payMode.toLowerCase()) {
      case 'cash':
        return AppColors.primary;
      case 'card':
        return AppColors.chartBlue;
      case 'upi':
        return AppColors.chartTeal;
      default:
        return _palette[index % _palette.length];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Payment Mix', subtitle: 'Last 30 days'),
          const SizedBox(height: 6),
          summaryAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'Could not load payment mix.',
                  style: AppTypography.bodyMuted.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
            ),
            data: (summary) {
              if (summary.paymentMix.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'No payments in the last 30 days.',
                      style: AppTypography.bodyMuted.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < summary.paymentMix.length; i++)
                    LabeledProgressRow(
                      label: summary.paymentMix[i].payMode,
                      valueLabel: '₹${summary.paymentMix[i].amount.toStringAsFixed(0)} · ${summary.paymentMix[i].percent.toStringAsFixed(0)}%',
                      fraction: summary.paymentMix[i].percent / 100,
                      color: _colorFor(summary.paymentMix[i].payMode, i),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
