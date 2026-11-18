import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/license_holder_report.dart';
import '../../data/reports_providers.dart';

/// License No | Name | Validity | Bills | Qty (Case) | Qty (Bottles) |
/// Amount — one row per license sold against in the selected range,
/// highest quantity first, with a totals row.
class LicenseHolderReportTable extends ConsumerWidget {
  const LicenseHolderReportTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(licenseHolderReportProvider);
    const title = 'License Holder Report';

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          reportAsync.when(
            loading: () => const SectionHeader(title: title, subtitle: 'Loading…'),
            error: (error, _) => SectionHeader(title: title, subtitle: 'Could not load: $error'),
            data: (report) => SectionHeader(
              title: title,
              subtitle: '${_fmt(report.from)} to ${_fmt(report.to)} · '
                  '${report.rows.length} license${report.rows.length == 1 ? '' : 's'}',
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
              if (report.rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text('No sales against a license in this date range.', style: AppTypography.bodyMuted),
                  ),
                );
              }
              return Column(
                children: [
                  _row(context, const ['SR', 'LICENSE NO', 'NAME', 'VALIDITY', 'BILLS', 'QTY (CASE)', 'QTY (BOTTLES)', 'AMOUNT'],
                      header: true),
                  Divider(height: 1, color: AppColors.borderFor(context)),
                  for (var i = 0; i < report.rows.length; i++) _dataRow(context, i + 1, report.rows[i]),
                  Divider(height: 1, color: AppColors.borderFor(context)),
                  _row(
                    context,
                    [
                      '',
                      '',
                      'Total',
                      '',
                      '${report.totalBills}',
                      '${report.totalQtyCase}',
                      '${report.totalQtyBottles}',
                      '₹${report.totalAmount.toStringAsFixed(2)}',
                    ],
                    bold: true,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static const _flex = [1, 2, 4, 2, 1, 2, 2, 2];

  Widget _dataRow(BuildContext context, int sr, LicenseHolderReportRow r) => _row(context, [
        '$sr',
        r.permitNo,
        r.name.isEmpty ? '—' : r.name,
        r.validity.isEmpty ? '—' : r.validity,
        '${r.bills}',
        '${r.qtyCase}',
        '${r.qtyBottles}',
        '₹${r.amount.toStringAsFixed(2)}',
      ]);

  Widget _row(BuildContext context, List<String> cells, {bool header = false, bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: header || bold ? 10 : 9),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: _flex[i],
              child: Text(
                cells[i],
                textAlign: i >= 4 ? TextAlign.end : TextAlign.start,
                overflow: TextOverflow.ellipsis,
                style: header
                    ? AppTypography.label.copyWith(color: AppColors.textMutedFor(context))
                    : i == 1
                        ? AppTypography.mono.copyWith(fontSize: 12, color: AppColors.textSecondaryFor(context))
                        : AppTypography.body.copyWith(
                            fontWeight: bold || i == 2 ? FontWeight.w700 : FontWeight.w500,
                            color: i == 0 ? AppColors.textMutedFor(context) : AppColors.textPrimaryFor(context),
                          ),
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')}-${months[d.month - 1]}-${d.year}';
  }
}
