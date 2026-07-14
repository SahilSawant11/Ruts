import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/layout/app_shell.dart';
import '../widgets/daily_sale_report_table.dart';
import '../widgets/report_filters_card.dart';
import '../widgets/report_kpi_row.dart';
import '../widgets/report_tabs.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportTab _tab = ReportTab.dayWise;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      moduleTitle: 'Reports',
      moduleShortcutLabel: 'Analysis',
      body: SingleChildScrollView(
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
                      Text('Day-wise, monthly and custom analysis across sales & purchases.',
                          style: AppTypography.bodyMuted),
                    ],
                  ),
                ),
                SecondaryButton(label: 'Export Excel', icon: Icons.download_rounded, onPressed: () {}),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ReportTabs(selected: _tab, onChanged: (tab) => setState(() => _tab = tab)),
            const SizedBox(height: AppSpacing.lg),
            const ReportFiltersCard(),
            const SizedBox(height: AppSpacing.lg),
            const ReportKpiRow(),
            const SizedBox(height: AppSpacing.lg),
            const DailySaleReportTable(),
          ],
        ),
      ),
    );
  }
}
