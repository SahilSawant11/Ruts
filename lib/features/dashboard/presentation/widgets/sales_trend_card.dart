import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/charts/vertical_bar_chart.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/dashboard_providers.dart';

class SalesTrendCard extends ConsumerWidget {
  const SalesTrendCard({super.key});

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _formatAmount(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Sales — last 7 days', subtitle: 'Net amount (₹)'),
          const SizedBox(height: 12),
          summaryAsync.when(
            loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => SizedBox(
              height: 220,
              child: Center(child: Text('Could not load trend.', style: AppTypography.bodyMuted)),
            ),
            data: (summary) {
              final points = summary.last7Days;
              final maxAmount = points.map((p) => p.amount).fold<double>(1, (a, b) => a > b ? a : b);

              return VerticalBarChart(
                data: [
                  for (final point in points)
                    VerticalBarData(
                      label: _weekdays[(point.date.weekday - 1) % 7],
                      valueLabel: _formatAmount(point.amount),
                      fraction: maxAmount > 0 ? point.amount / maxAmount : 0,
                      color: point.date.day == DateTime.now().day && point.date.month == DateTime.now().month
                          ? AppColors.chartAmber
                          : null,
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
