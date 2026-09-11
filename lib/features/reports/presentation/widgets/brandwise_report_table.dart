import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/brandwise_report_provider.dart';
import '../../data/models/brandwise_report_dto.dart';

/// On-screen table matching the excise register layout.
/// The BRAND NAME and T.P. No. columns are frozen on the left while
/// the 4 balance quantity groups (28 size columns) scroll horizontally.
/// Clicking any row highlights the entire row across frozen and scrollable panels.
class BrandwiseReportTable extends ConsumerWidget {
  const BrandwiseReportTable({super.key});

  static const sizeLabels = ['750ml', '375ml', '180ml', '650ml', '500ml CAN', '330ml CAN', '330ml'];
  static const groupLabels = ['OPENING BALANCE', 'PURCHASE', 'SALE', 'CLOSING BALANCE'];

  // Width dimensions — generous brand width to avoid truncation
  static const brandWidth = 270.0;
  static const tpWidth = 60.0;
  static const frozenTotalWidth = brandWidth + tpWidth; // 330.0
  static const sizeColWidth = 54.0;
  static const groupSepWidth = 2.0;

  // Row heights — strictly fixed so frozen and scrollable rows stay 1:1 aligned.
  static const groupHeaderH = 36.0;
  static const sizeHeaderH = 28.0;
  static const headerTotalH = groupHeaderH + sizeHeaderH; // 64.0
  static const categoryH = 30.0;
  static const dataRowH = 30.0;
  static const subtotalH = 32.0;

  // Total scrollable content width: (7 cols * 4 groups * 54.0) + (3 separators * 2.0) = 1518.0
  static const scrollableWidth = (sizeColWidth * 28) + (groupSepWidth * 3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(brandwiseReportProvider);
    final isDark = AppColors.isDark(context);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          reportAsync.when(
            loading: () => const SectionHeader(title: 'Brandwise Stock Report', subtitle: 'Loading…'),
            error: (e, _) => SectionHeader(title: 'Brandwise Stock Report', subtitle: 'Error: $e'),
            data: (report) {
              final totalItems = report.categories.fold<int>(0, (s, c) => s + c.items.length);
              return SectionHeader(
                title: 'Brandwise Stock Report',
                subtitle: '${_fmtDate(report.reportDate)} · $totalItems brand${totalItems == 1 ? '' : 's'}',
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          reportAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (report) {
              final totalItems = report.categories.fold<int>(0, (s, c) => s + c.items.length);
              if (totalItems == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: Text('No data for this date.', style: AppTypography.bodyMuted)),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: _FrozenColumnTable(
                  isDark: isDark,
                  report: report,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')}-${months[d.month - 1]}-${d.year}';
  }
}

// ---------------------------------------------------------------------------
//  Interactive Frozen-column table widget with row highlight support
// ---------------------------------------------------------------------------

class _FrozenColumnTable extends StatefulWidget {
  const _FrozenColumnTable({required this.isDark, required this.report});

  final bool isDark;
  final BrandwiseReportDto report;

  @override
  State<_FrozenColumnTable> createState() => _FrozenColumnTableState();
}

class _FrozenColumnTableState extends State<_FrozenColumnTable> {
  // Selected row key: "${category.name}__$i"
  String? _selectedRowKey;

  // Constants
  static const _tpW = BrandwiseReportTable.tpWidth;
  static const _frozenW = BrandwiseReportTable.frozenTotalWidth;
  static const _sizeW = BrandwiseReportTable.sizeColWidth;
  static const _sepW = BrandwiseReportTable.groupSepWidth;
  static const _scrollW = BrandwiseReportTable.scrollableWidth;

  static const _headerH = BrandwiseReportTable.headerTotalH;
  static const _groupH = BrandwiseReportTable.groupHeaderH;
  static const _sizeH = BrandwiseReportTable.sizeHeaderH;
  static const _catH = BrandwiseReportTable.categoryH;
  static const _rowH = BrandwiseReportTable.dataRowH;
  static const _subH = BrandwiseReportTable.subtotalH;

  // Colors
  Color get _tableBorder => widget.isDark ? const Color(0xFF333B50) : const Color(0xFFCFD5E2);
  Color get _cellBorder => widget.isDark ? const Color(0xFF262D3D) : const Color(0xFFE2E6EE);
  Color get _strongBorder => widget.isDark ? const Color(0xFF47526D) : const Color(0xFFB5BDCC);

  Color get _headerBg => widget.isDark ? const Color(0xFF1E263E) : const Color(0xFF3B4872);
  Color get _subHeaderBg => widget.isDark ? const Color(0xFF26304D) : const Color(0xFF4F5D8A);
  Color get _catBg => widget.isDark ? const Color(0xFF282236) : const Color(0xFFF2EAF6);
  Color get _subtotalBg => widget.isDark ? const Color(0xFF1C2233) : const Color(0xFFEBF0F8);

  Color _rowBg(bool even) =>
      widget.isDark
          ? (even ? const Color(0xFF161A26) : const Color(0xFF1B2030))
          : (even ? Colors.white : const Color(0xFFF8FAFC));

  Color _rowHighlightBg() =>
      widget.isDark
          ? const Color(0xFF3B82F6).withValues(alpha: 0.28)
          : const Color(0xFF3B82F6).withValues(alpha: 0.12);

  Color _resolveRowBg(String key, bool even) {
    if (_selectedRowKey == key) {
      return _rowHighlightBg();
    }
    return _rowBg(even);
  }

  void _onRowTap(String key) {
    setState(() {
      _selectedRowKey = (_selectedRowKey == key) ? null : key;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _tableBorder, width: 1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Frozen Left Panel (Brand Name + T.P. No.) ──
          Container(
            width: _frozenW,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: _strongBorder, width: 1.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isDark ? Colors.black54 : Colors.black12),
                  blurRadius: 5,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildFrozenColumn(),
            ),
          ),

          // ── Scrollable Right Panel (Quantities) ──
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _scrollW,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildScrollableColumn(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  //  FROZEN LEFT PANEL
  // =========================================================================

  List<Widget> _buildFrozenColumn() {
    final rows = <Widget>[];

    // ── Header (Full 64px height, vertically centered) ──
    rows.add(Container(
      height: _headerH,
      decoration: BoxDecoration(
        color: _headerBg,
        border: Border(
          bottom: BorderSide(color: _strongBorder, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: _headerH,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: _cellBorder.withValues(alpha: 0.3))),
              ),
              child: const Text(
                'BRAND NAME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          const SizedBox(
            width: _tpW,
            height: _headerH,
            child: Center(
              child: Text(
                'T.P. No.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    ));

    // ── Categories + Data rows ──
    for (final category in widget.report.categories) {
      // Category header
      rows.add(Container(
        height: _catH,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _catBg,
          border: Border(
            top: BorderSide(color: _strongBorder, width: 1),
            bottom: BorderSide(color: _tableBorder, width: 1),
          ),
        ),
        child: Text(
          category.name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: widget.isDark ? const Color(0xFFD4B2E5) : const Color(0xFF5E3278),
            letterSpacing: 1.1,
          ),
        ),
      ));

      // Items
      for (int i = 0; i < category.items.length; i++) {
        final item = category.items[i];
        final rowKey = '${category.name}__$i';
        final isSelected = _selectedRowKey == rowKey;
        final bg = _resolveRowBg(rowKey, i.isEven);

        rows.add(Material(
          color: bg,
          child: InkWell(
            onTap: () => _onRowTap(rowKey),
            hoverColor: widget.isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            child: Container(
              height: _rowH,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.5) : _cellBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: _rowH,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: _cellBorder)),
                      ),
                      child: Tooltip(
                        message: item.brandName,
                        waitDuration: const Duration(milliseconds: 300),
                        child: Text(
                          item.brandName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? (widget.isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                                : (widget.isDark ? const Color(0xFFE2E7F5) : const Color(0xFF1E2538)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _tpW,
                    height: _rowH,
                    child: Center(
                      child: Text(
                        item.tpNo ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          color: isSelected
                              ? (widget.isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                              : (widget.isDark ? const Color(0xFF8B93AA) : const Color(0xFF8890A4)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
      }

      // Subtotal
      rows.add(Container(
        height: _subH,
        decoration: BoxDecoration(
          color: _subtotalBg,
          border: Border(
            bottom: BorderSide(color: _strongBorder, width: 1.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: _subH,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: _cellBorder)),
                ),
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: widget.isDark ? Colors.white : const Color(0xFF161C2E),
                  ),
                ),
              ),
            ),
            const SizedBox(width: _tpW),
          ],
        ),
      ));
    }

    return rows;
  }

  // =========================================================================
  //  SCROLLABLE RIGHT PANEL (28 size columns across 4 balance groups)
  // =========================================================================

  List<Widget> _buildScrollableColumn() {
    final rows = <Widget>[];

    // ── Tier 1: Group Headers (height 36) ──
    rows.add(SizedBox(
      height: _groupH,
      child: Row(
        children: [
          for (int g = 0; g < BrandwiseReportTable.groupLabels.length; g++) ...[
            if (g > 0) Container(width: _sepW, color: _strongBorder),
            Container(
              width: _sizeW * 7,
              height: _groupH,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _headerBg,
                border: Border(bottom: BorderSide(color: _cellBorder.withValues(alpha: 0.3))),
              ),
              child: Text(
                BrandwiseReportTable.groupLabels[g],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ],
      ),
    ));

    // ── Tier 2: Size Sub-Headers (height 28) ──
    rows.add(SizedBox(
      height: _sizeH,
      child: Row(
        children: [
          for (int g = 0; g < 4; g++) ...[
            if (g > 0) Container(width: _sepW, color: _strongBorder),
            for (final label in BrandwiseReportTable.sizeLabels)
              Container(
                width: _sizeW,
                height: _sizeH,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: _subHeaderBg,
                  border: Border(
                    bottom: BorderSide(color: _strongBorder, width: 1.5),
                    right: BorderSide(color: _cellBorder.withValues(alpha: 0.25)),
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? const Color(0xFFCAD0E5) : Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ),
          ],
        ],
      ),
    ));

    // ── Categories + Data rows ──
    for (final category in widget.report.categories) {
      // Category background strip
      rows.add(Container(
        height: _catH,
        decoration: BoxDecoration(
          color: _catBg,
          border: Border(
            top: BorderSide(color: _strongBorder, width: 1),
            bottom: BorderSide(color: _tableBorder, width: 1),
          ),
        ),
      ));

      // Items
      for (int i = 0; i < category.items.length; i++) {
        final item = category.items[i];
        final rowKey = '${category.name}__$i';
        final isSelected = _selectedRowKey == rowKey;
        final bg = _resolveRowBg(rowKey, i.isEven);

        rows.add(Material(
          color: bg,
          child: InkWell(
            onTap: () => _onRowTap(rowKey),
            hoverColor: widget.isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            child: SizedBox(
              height: _rowH,
              child: Row(
                children: [
                  ..._buildQtyGroup(item.openingBalance, groupIndex: 0, bg: bg, isRowSelected: isSelected),
                  ..._buildQtyGroup(item.purchase, groupIndex: 1, bg: bg, isRowSelected: isSelected),
                  ..._buildQtyGroup(item.sale, groupIndex: 2, bg: bg, isRowSelected: isSelected),
                  ..._buildQtyGroup(item.closingBalance, groupIndex: 3, bg: bg, isRowSelected: isSelected),
                ],
              ),
            ),
          ),
        ));
      }

      // Subtotal
      rows.add(SizedBox(
        height: _subH,
        child: Row(
          children: [
            ..._buildQtyGroup(category.subtotal.openingBalance, groupIndex: 0, bg: _subtotalBg, bold: true),
            ..._buildQtyGroup(category.subtotal.purchase, groupIndex: 1, bg: _subtotalBg, bold: true),
            ..._buildQtyGroup(category.subtotal.sale, groupIndex: 2, bg: _subtotalBg, bold: true),
            ..._buildQtyGroup(category.subtotal.closingBalance, groupIndex: 3, bg: _subtotalBg, bold: true),
          ],
        ),
      ));
    }

    return rows;
  }

  // ── Helper to build 7 quantity cells for a balance group ──
  List<Widget> _buildQtyGroup(
    BrandwiseSizeQty qty, {
    required int groupIndex,
    required Color bg,
    bool bold = false,
    bool isRowSelected = false,
  }) {
    final bottomBorder = bold
        ? BorderSide(color: _strongBorder, width: 1.5)
        : BorderSide(
            color: isRowSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.5) : _cellBorder,
          );

    return [
      if (groupIndex > 0) Container(width: _sepW, color: _strongBorder),
      for (int i = 0; i < 7; i++)
        Container(
          width: _sizeW,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              bottom: bottomBorder,
              right: BorderSide(color: _cellBorder.withValues(alpha: 0.6)),
            ),
          ),
          child: Text(
            qty.byIndex(i) == 0 ? '' : '${qty.byIndex(i)}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: bold
                  ? FontWeight.w800
                  : (isRowSelected ? FontWeight.w700 : FontWeight.w500),
              fontFeatures: const [FontFeature.tabularFigures()],
              color: bold
                  ? (widget.isDark ? Colors.white : const Color(0xFF151B2B))
                  : (isRowSelected
                      ? (widget.isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                      : (widget.isDark ? const Color(0xFFCFD5E8) : const Color(0xFF333B50))),
            ),
          ),
        ),
    ];
  }
}
