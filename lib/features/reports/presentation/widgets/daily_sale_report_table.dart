import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/models/sales_report_dto.dart';
import '../../data/reports_providers.dart';

/// Matches the client's real DailySaleReport export exactly:
/// Sale Date | Local Item Code | Brand Name | Size | Qty (Case) |
/// Qty (Loose Bottle) — one row per material, aggregated across the
/// selected date range, with a totals row at the bottom.
class DailySaleReportTable extends ConsumerWidget {
  const DailySaleReportTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(salesReportProvider);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          reportAsync.when(
            loading: () => const SectionHeader(title: 'Daily Sale Report', subtitle: 'Loading…'),
            error: (error, _) => SectionHeader(title: 'Daily Sale Report', subtitle: 'Could not load: $error'),
            data: (report) => SectionHeader(
              title: 'Daily Sale Report',
              subtitle: '${_fmt(report.fromDate)} to ${_fmt(report.toDate)} · ${report.items.length} item${report.items.length == 1 ? '' : 's'}',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          reportAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (report) {
              if (report.items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: Text('No sales in this date range.', style: AppTypography.bodyMuted)),
                );
              }
              return Column(
                children: [
                  _headerRow(),
                  const Divider(height: 1, color: AppColors.border),
                  for (var i = 0; i < report.items.length; i++) _dataRow(i + 1, report.items[i]),
                  const Divider(height: 1, color: AppColors.border),
                  _totalsRow(report),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')}-${months[d.month - 1]}-${d.year}';
  }

  Widget _headerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _cell('SR', flex: 1, header: true),
          _cell('LOCAL ITEM CODE', flex: 2, header: true),
          _cell('BRAND NAME', flex: 4, header: true),
          _cell('SIZE', flex: 2, header: true),
          _cell('QTY (CASE)', flex: 1, header: true, alignEnd: true),
          _cell('QTY (LOOSE BOTTLE)', flex: 2, header: true, alignEnd: true),
        ],
      ),
    );
  }

  Widget _dataRow(int sr, SalesReportItemDto item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          _cell('$sr', flex: 1, muted: true),
          _cell(item.materialId, flex: 2, mono: true),
          _cell(item.materialName, flex: 4, bold: true),
          _cell(item.packing ?? '—', flex: 2),
          _cell('${item.qtyCase}', flex: 1, alignEnd: true),
          _cell('${item.qtyLoose}', flex: 2, alignEnd: true),
        ],
      ),
    );
  }

  Widget _totalsRow(SalesReportDto report) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _cell('', flex: 1),
          _cell('', flex: 2),
          _cell('Total', flex: 4, bold: true),
          _cell('', flex: 2),
          _cell('${report.totalQtyCase}', flex: 1, alignEnd: true, bold: true),
          _cell('${report.totalQtyLoose}', flex: 2, alignEnd: true, bold: true),
        ],
      ),
    );
  }

  Widget _cell(
    String text, {
    required int flex,
    bool header = false,
    bool alignEnd = false,
    bool bold = false,
    bool mono = false,
    bool muted = false,
  }) {
    TextStyle style;
    if (header) {
      style = AppTypography.label;
    } else if (mono) {
      style = AppTypography.mono.copyWith(fontSize: 12, color: AppColors.textSecondary);
    } else {
      style = AppTypography.body.copyWith(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: muted ? AppColors.textMuted : AppColors.textPrimary,
      );
    }
    return Expanded(
      flex: flex,
      child: Text(text, textAlign: alignEnd ? TextAlign.end : TextAlign.start, overflow: TextOverflow.ellipsis, style: style),
    );
  }
}
