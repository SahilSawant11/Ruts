import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/data/kpi_card.dart';
import '../../../inventory/data/inventory_providers.dart';
import '../../data/dashboard_providers.dart';

class DashboardKpiRow extends ConsumerWidget {
  const DashboardKpiRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final inventoryAsync = ref.watch(inventoryOverviewProvider);

    return summaryAsync.when(
      loading: () => const _KpiSkeletonRow(),
      error: (_, __) => const _KpiSkeletonRow(),
      data: (summary) {
        final lowStockCount = inventoryAsync.maybeWhen(
          data: (items) => items.where((i) => i.isLowStock || i.isOutOfStock).length,
          orElse: () => null,
        );

        String? deltaText(double? percent) {
          if (percent == null) return null;
          final arrow = percent >= 0 ? '▲' : '▼';
          return '$arrow ${percent.abs().toStringAsFixed(1)}% vs yesterday';
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: KpiCard(
                label: "Today's Sales",
                value: '₹${summary.todaySales.toStringAsFixed(0)}',
                icon: Icons.shopping_cart_outlined,
                trendText: deltaText(summary.salesDeltaPercent),
                trendUp: summary.salesDeltaPercent == null ? null : summary.salesDeltaPercent! >= 0,
                progress: summary.dailyTarget > 0 ? (summary.todaySales / summary.dailyTarget) : null,
                progressCaption: summary.dailyTarget > 0
                    ? '${(summary.todaySales / summary.dailyTarget * 100).clamp(0, 999).toStringAsFixed(0)}% of ₹${(summary.dailyTarget / 100000).toStringAsFixed(1)}L daily target'
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KpiCard(
                label: 'Bills',
                value: '${summary.todayBillCount}',
                icon: Icons.receipt_long_outlined,
                trendText: deltaText(summary.billsDeltaPercent),
                trendUp: summary.billsDeltaPercent == null ? null : summary.billsDeltaPercent! >= 0,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KpiCard(
                label: 'Avg Bill Value',
                value: '₹${summary.avgBillValue.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KpiCard(
                label: 'Low Stock Items',
                value: lowStockCount?.toString() ?? '—',
                icon: Icons.warning_amber_rounded,
                trendText: (lowStockCount ?? 0) > 0 ? 'needs reorder' : null,
                tone: (lowStockCount ?? 0) > 0 ? KpiTone.amber : KpiTone.normal,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiSkeletonRow extends StatelessWidget {
  const _KpiSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: KpiCard(label: "Today's Sales", value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Bills', value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Avg Bill Value', value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Low Stock Items', value: '—')),
      ],
    );
  }
}
