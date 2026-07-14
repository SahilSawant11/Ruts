import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class _ReportRow {
  const _ReportRow(this.sr, this.date, this.itemCode, this.brand, this.size, this.qtyCase, this.qtyLoose);
  final int sr;
  final String date;
  final String itemCode;
  final String brand;
  final String size;
  final int qtyCase;
  final int qtyLoose;
}

/// "Daily Sale Report" — mirrors the reference Excel export layout.
/// Static dummy rows for now; will read from a real reports endpoint
/// once one exists (the Sales API only exposes today's bills so far).
class DailySaleReportTable extends StatelessWidget {
  const DailySaleReportTable({super.key});

  static const _rows = [
    _ReportRow(1, '27-Jun-2026', 'SCMBR0027088', 'Budweiser Magnum Strong Beer', '500ml (CAN)', 5, 11),
    _ReportRow(2, '27-Jun-2026', 'SCMBR0027089', 'Budweiser Magnum Strong Beer', '650ml', 4, 6),
    _ReportRow(3, '27-Jun-2026', 'SCMBR0018131', 'Budweiser Premium King of Beer', '500ml (CAN)', 6, 8),
    _ReportRow(4, '27-Jun-2026', 'SCMBR0018132', 'Budweiser Premium King of Beer', '650ml', 4, 4),
    _ReportRow(5, '27-Jun-2026', 'SCMBR0018962', 'Carlsberg Smooth Premium Lager', '500ml (CAN)', 7, 2),
    _ReportRow(6, '27-Jun-2026', 'SCMBR0018963', 'Carlsberg Smooth Premium Lager', '650ml', 3, 0),
    _ReportRow(7, '27-Jun-2026', 'SCMBR0018159', 'Carlsberg Strong Beer', '500ml (CAN)', 5, 5),
    _ReportRow(8, '27-Jun-2026', 'SCMBR0018160', 'Carlsberg Strong Beer', '650ml', 4, 2),
    _ReportRow(9, '27-Jun-2026', 'SCMBR0018149', 'Kingfisher Premium Lager Beer', '650ml', 4, 0),
    _ReportRow(10, '27-Jun-2026', 'SCMBR0018626', 'Kingfisher Strong Premium Beer', '330ml (CAN)', 3, 0),
    _ReportRow(11, '27-Jun-2026', 'SCMKB0027896', 'Kingfisher Strong Premium Beer', '500ml (CAN)', 4, 1),
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Daily Sale Report',
            subtitle: 'mirrors the Product 6 DailySaleReport Excel export · 27-Jun-2026',
          ),
          const SizedBox(height: AppSpacing.sm),
          _headerRow(),
          const Divider(height: 1, color: AppColors.border),
          for (final row in _rows) _dataRow(row),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _cell('SR', flex: 1, header: true),
          _cell('SALE DATE', flex: 2, header: true),
          _cell('LOCAL ITEMCODE', flex: 2, header: true),
          _cell('BRAND NAME', flex: 4, header: true),
          _cell('SIZE', flex: 2, header: true),
          _cell('QTY (CASE)', flex: 1, header: true, alignEnd: true),
          _cell('QTY (LOOSE)', flex: 1, header: true, alignEnd: true),
        ],
      ),
    );
  }

  Widget _dataRow(_ReportRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          _cell('${row.sr}', flex: 1, muted: true),
          _cell(row.date, flex: 2),
          _cell(row.itemCode, flex: 2, mono: true),
          _cell(row.brand, flex: 4, bold: true),
          _cell(row.size, flex: 2),
          _cell('${row.qtyCase}', flex: 1, alignEnd: true),
          _cell('${row.qtyLoose}', flex: 1, alignEnd: true),
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
