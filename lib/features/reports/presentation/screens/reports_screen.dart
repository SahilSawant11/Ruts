import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../data/reports_providers.dart';
import '../widgets/daily_sale_report_table.dart';
import '../widgets/report_filters_card.dart';
import '../widgets/report_kpi_row.dart';
import '../widgets/report_tabs.dart';

/// Widget tree:
/// ReportsScreen
///   ├── header (title + Export Excel)
///   ├── ReportTabs — switching tabs sets a sensible default date
///   │     range (today / this month) via reportDateRangeProvider;
///   │     Custom leaves whatever range is already selected alone
///   ├── ReportFiltersCard — From/To pickers + Generate, can override
///   │     whatever the tab set as a starting point
///   ├── ReportKpiRow — reads salesReportProvider
///   └── DailySaleReportTable — reads salesReportProvider
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportTab _tab = ReportTab.dayWise;

  void _onTabChanged(ReportTab tab) {
    setState(() => _tab = tab);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (tab) {
      case ReportTab.dayWise:
        ref.read(reportDateRangeProvider.notifier).state = DateTimeRange(start: today, end: today);
      case ReportTab.monthly:
        final firstOfMonth = DateTime(now.year, now.month, 1);
        ref.read(reportDateRangeProvider.notifier).state = DateTimeRange(start: firstOfMonth, end: today);
      case ReportTab.custom:
        // Leave whatever range is already selected — Custom is meant
        // for the person to pick their own via the filter card.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reports', style: AppTypography.h1),
                    const SizedBox(height: 4),
                    Text('Day-wise, monthly and custom analysis across sales.', style: AppTypography.bodyMuted),
                  ],
                ),
              ),
              SecondaryButton(label: 'Export Excel', icon: Icons.download_rounded, onPressed: () {}),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ReportTabs(selected: _tab, onChanged: _onTabChanged),
          const SizedBox(height: AppSpacing.lg),
          const ReportFiltersCard(),
          const SizedBox(height: AppSpacing.lg),
          const ReportKpiRow(),
          const SizedBox(height: AppSpacing.lg),
          const DailySaleReportTable(),
        ],
      ),
    );
  }
}
