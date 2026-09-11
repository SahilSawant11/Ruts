import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/data/kpi_card.dart';
import '../../data/brandwise_report_provider.dart';

class BrandwiseKpiRow extends ConsumerWidget {
  const BrandwiseKpiRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(brandwiseReportProvider);

    return reportAsync.when(
      loading: () => const _Skeleton(),
      error: (_, __) => const _Skeleton(),
      data: (report) {
        int fermentedSale = 0;
        int mildSale = 0;
        int wineSale = 0;

        for (final cat in report.categories) {
          final total = cat.subtotal.sale.total;
          switch (cat.name) {
            case 'FERMENTED BEER':
              fermentedSale = total;
            case 'MILD BEER':
              mildSale = total;
            case 'WINE':
              wineSale = total;
          }
        }

        final grandTotal = fermentedSale + mildSale + wineSale;

        return Row(
          children: [
            Expanded(child: KpiCard(label: 'Fermented Beer (Sale)', value: '$fermentedSale')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: KpiCard(label: 'Mild Beer (Sale)', value: '$mildSale')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: KpiCard(label: 'Wine (Sale)', value: '$wineSale')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: KpiCard(label: 'Total Sale', value: '$grandTotal')),
          ],
        );
      },
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: KpiCard(label: 'Fermented Beer (Sale)', value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Mild Beer (Sale)', value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Wine (Sale)', value: '—')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Total Sale', value: '—')),
      ],
    );
  }
}
