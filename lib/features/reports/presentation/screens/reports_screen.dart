import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../masters/data/masters_providers.dart';
import '../../data/reports_providers.dart';
import '../widgets/daily_sale_report_table.dart';
import '../widgets/license_holder_report_table.dart';
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

/// Which report the screen shows; both share the tabs and date range.
enum _ReportView { scmDailySale, licenseHolders }

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportTab _tab = ReportTab.dayWise;
  _ReportView _view = _ReportView.scmDailySale;

  void _refresh() {
    ref.invalidate(salesReportProvider);
    ref.invalidate(licenseHolderReportProvider);
  }
  bool _isExporting = false;

  void _onTabChanged(ReportTab tab) {
    setState(() => _tab = tab);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (tab) {
      case ReportTab.dayWise:
        ref.read(reportDateRangeProvider.notifier).state = DateTimeRange(start: todayStart, end: todayEnd);
        _refresh();
      case ReportTab.monthly:
        final firstOfMonth = DateTime(now.year, now.month, 1, 0, 0, 0);
        ref.read(reportDateRangeProvider.notifier).state = DateTimeRange(start: firstOfMonth, end: todayEnd);
        _refresh();
      case ReportTab.custom:
        // Leave whatever range is already selected — Custom is meant
        // for the person to pick their own via the filter card.
        break;
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      // SCM portal upload sheet: every liquor item for each day in the
      // range, sold quantities filled in (blank when nothing sold).
      final range = ref.read(reportDateRangeProvider);
      final file = _view == _ReportView.licenseHolders
          ? await ref
              .read(licenseHolderReportExporterProvider)
              .export(await ref.read(licenseHolderReportProvider.future))
          : await ref
              .read(reportExcelExporterProvider)
              .export(ref.read(appDatabaseProvider), range.start, range.end);
      if (!mounted) return;
      _showSnack('Excel report saved to ${file.path}');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not export Excel: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Widget _viewSwitch(BuildContext context) {
    Widget segment(_ReportView view, String label) {
      final selected = _view == view;
      return Material(
        color: selected ? AppColors.backgroundFor(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        elevation: selected ? 1 : 0,
        child: InkWell(
          onTap: () => setState(() => _view = view),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 9),
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textSecondaryFor(context),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(_ReportView.scmDailySale, 'SCM Daily Sale'),
          segment(_ReportView.licenseHolders, 'License Holders'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportFiltersCard(
            tabs: ReportTabs(selected: _tab, onChanged: _onTabChanged),
            trailingAction: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Offline MVP: Queued offline chip commented out
                // pendingSyncAsync.when(
                //   loading: () => const SizedBox.shrink(),
                //   error: (_, __) => const SizedBox.shrink(),
                //   data: (count) => count > 0
                //       ? const Padding(
                //           padding: EdgeInsets.only(right: AppSpacing.sm),
                //           child: StatusChip(label: 'Queued offline', tone: StatusChipTone.neutral),
                //         )
                //       : const SizedBox.shrink(),
                // ),
                SecondaryButton(
                  label: 'Refresh',
                  icon: AppIcons.refresh,
                  onPressed: () {
                    _refresh();
                    ref.invalidate(categoriesListProvider);
                    ref.invalidate(manufacturersListProvider);
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                SecondaryButton(
                  label: _isExporting ? 'Exporting…' : 'Export Excel',
                  icon: AppIcons.download,
                  onPressed: _isExporting ? null : _exportExcel,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _viewSwitch(context),
          const SizedBox(height: AppSpacing.md),
          if (_view == _ReportView.scmDailySale) ...[
            const ReportKpiRow(),
            const SizedBox(height: AppSpacing.lg),
            const DailySaleReportTable(),
          ] else
            const LicenseHolderReportTable(),
        ],
      ),
    );
  }
}
