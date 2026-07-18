import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/data/kpi_card.dart';
import '../../data/reports_providers.dart';

class ReportKpiRow extends ConsumerWidget {
  const ReportKpiRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(salesReportProvider);

    return reportAsync.when(
      loading: () => const _KpiSkeletonRow(),
      error: (_, __) => const _KpiSkeletonRow(),
      data: (report) => Row(
        children: [
          Expanded(child: KpiCard(label: 'Bills', value: '${report.totalBills}')),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: KpiCard(label: 'Distinct Brands', value: '${report.distinctBrands}')),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: KpiCard(label: 'Qty (Case)', value: '${report.totalQtyCase}')),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: KpiCard(label: 'Qty (Loose Bottle)', value: '${report.totalQtyLoose}')),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: KpiCard(label: 'Total Amount', value: '₹${report.totalAmount.toStringAsFixed(0)}')),
        ],
      ),
    );
  }
}

class _KpiSkeletonRow extends StatelessWidget {
  const _KpiSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: KpiCard(label: 'Bills', value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Distinct Brands', value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Qty (Case)', value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Qty (Loose Bottle)', value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Total Amount', value: '—')),
      ],
    );
  }
}
