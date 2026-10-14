import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../data/brandwise_report_provider.dart';
import '../../data/counter_brandwise_report_provider.dart';
import '../widgets/brandwise_filters_card.dart';
import '../widgets/brandwise_kpi_row.dart';
import '../widgets/brandwise_report_table.dart';
import '../widgets/counter_brandwise_kpi_row.dart';
import '../widgets/counter_brandwise_report_table.dart';

/// Brandwise Stock Report screen — single-day excise register showing
/// Opening Balance → Purchase → Sale → Closing Balance per brand or
/// aggregated per manufacturer, grouped by Fermented Beer / Mild Beer / Wine.
class BrandwiseReportScreen extends ConsumerStatefulWidget {
  const BrandwiseReportScreen({super.key});

  @override
  ConsumerState<BrandwiseReportScreen> createState() => _BrandwiseReportScreenState();
}

class _BrandwiseReportScreenState extends ConsumerState<BrandwiseReportScreen> {
  bool _isExporting = false;

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    final mode = ref.read(brandwiseViewModeProvider);
    try {
      if (mode == BrandwiseViewMode.counterBrandwise) {
        final report = await ref.read(counterBrandwiseReportProvider.future);
        final totalItems = report.categories.fold<int>(0, (s, c) => s + c.items.length);
        if (totalItems == 0) {
          _showSnack('No data to export for this date.', isError: true);
          return;
        }

        final exporter = ref.read(counterBrandwiseExcelExporterProvider);
        final file = await exporter.exportCounterBrandwiseReport(report);
        if (!mounted) return;
        _showSnack('Excel saved to ${file.path}');
      } else {
        final report = await ref.read(brandwiseReportProvider.future);
        final totalItems = report.categories.fold<int>(0, (s, c) => s + c.items.length);
        if (totalItems == 0) {
          _showSnack('No data to export for this date.', isError: true);
          return;
        }

        final exporter = ref.read(brandwiseExcelExporterProvider);
        final file = await exporter.exportBrandwiseReport(report);
        if (!mounted) return;
        _showSnack('Excel saved to ${file.path}');
      }
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

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(brandwiseViewModeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filters (with date picker, mode toggle, generate, export) ──
          BrandwiseFiltersCard(
            trailingAction: SecondaryButton(
              label: _isExporting ? 'Exporting…' : 'Export Excel',
              icon: Icons.download_rounded,
              onPressed: _isExporting ? null : _exportExcel,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── KPIs ──
          if (mode == BrandwiseViewMode.brandwise)
            const BrandwiseKpiRow()
          else
            const CounterBrandwiseKpiRow(),
          const SizedBox(height: AppSpacing.lg),

          // ── Table ──
          if (mode == BrandwiseViewMode.brandwise)
            const BrandwiseReportTable()
          else
            const CounterBrandwiseReportTable(),
        ],
      ),
    );
  }
}
