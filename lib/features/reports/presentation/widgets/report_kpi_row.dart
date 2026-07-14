import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/data/kpi_card.dart';

class ReportKpiRow extends StatelessWidget {
  const ReportKpiRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: KpiCard(label: 'Line Items', value: '22')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Total Cases', value: '126')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Total Loose Bottles', value: '43')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: KpiCard(label: 'Distinct Brands', value: '9')),
      ],
    );
  }
}
