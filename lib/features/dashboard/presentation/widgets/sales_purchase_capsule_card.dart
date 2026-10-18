import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/dashboard_providers.dart';
import '../../data/models/dashboard_summary_dto.dart';

/// 'Sales & Purchase' Capsule Bar Chart matching the mood board screenshot faithfully:
///  - Header with violet tag icon, 'Sales & Purchase' title, and time pills (1D · 1W · 1M · 1Y)
///  - Centered Legend: ● Total Purchase (Solid Purple) · ● Total Sale (Light Lavender)
///  - Side-by-side capsule pill columns for each period
///  - Left Y-axis (100K down to 0K) with dashed horizontal grid lines
class SalesPurchaseCapsuleCard extends ConsumerStatefulWidget {
  const SalesPurchaseCapsuleCard({super.key});

  @override
  ConsumerState<SalesPurchaseCapsuleCard> createState() =>
      _SalesPurchaseCapsuleCardState();
}

class _SalesPurchaseCapsuleCardState
    extends ConsumerState<SalesPurchaseCapsuleCard> {
  String _selectedRange = '1Y';
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final isDark = AppColors.isDark(context);

    // Color tokens matching screenshot
    const purchaseColor = Color(0xFF6E56CF); // Solid Purple
    final saleColor = isDark
        ? const Color(0xFF433D6B) // Dark mode muted lavender
        : const Color(0xFFE4E1FC); // Light mode soft lavender

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundFor(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderFor(context)),
        boxShadow: AppColors.cardShadowFor(context),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tag Icon + Title + Timeframe Pills
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? purchaseColor.withValues(alpha: 0.20)
                      : const Color(0xFFF1EEFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  size: 16,
                  color: purchaseColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Sales & Purchase',
                style: AppTypography.sectionTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
              const Spacer(),

              // Time Range Selector Pills (1D, 1W, 1M, 1Y)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B1E28) : const Color(0xFFF6F6F9),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                child: Row(
                  children: ['1D', '1W', '1M', '1Y'].map((range) {
                    final isSelected = _selectedRange == range;
                    return InkWell(
                      onTap: () => setState(() => _selectedRange = range),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF16161F))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          range,
                          style: AppTypography.mono.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? (isDark ? Colors.black : Colors.white)
                                : AppColors.textMutedFor(context),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Centered Legend: Total Purchase (Purple) · Total Sale (Lavender)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(
                color: purchaseColor,
                label: 'Total Purchase',
                context: context,
              ),
              const SizedBox(width: 24),
              _legendItem(
                color: saleColor,
                label: 'Total Sale',
                context: context,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Chart Canvas
          summaryAsync.when(
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox(
              height: 220,
              child: Center(child: Text('Could not load chart data')),
            ),
            data: (summary) {
              final comparisonPoints = _resolvePointsForRange(summary, _selectedRange);

              // Scale determination
              double maxObserved = 100000;
              for (final p in comparisonPoints) {
                if (p.salesAmount > maxObserved) maxObserved = p.salesAmount;
                if (p.purchaseAmount > maxObserved) maxObserved = p.purchaseAmount;
              }

              return SizedBox(
                height: 220,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Y-Axis Labels
                    SizedBox(
                      width: 38,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _YLabel(_formatAxisLabel(maxObserved)),
                          _YLabel(_formatAxisLabel(maxObserved * 0.8)),
                          _YLabel(_formatAxisLabel(maxObserved * 0.6)),
                          _YLabel(_formatAxisLabel(maxObserved * 0.4)),
                          _YLabel(_formatAxisLabel(maxObserved * 0.2)),
                          const _YLabel('0K'),
                        ],
                      ),
                    ),

                    // Grid & Side-by-side Capsule Columns
                    Expanded(
                      child: Stack(
                        children: [
                          // Dashed Horizontal Grid Lines
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                              (index) => CustomPaint(
                                size: const Size(double.infinity, 1),
                                painter: _DashedLinePainter(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFE5E5EB),
                                ),
                              ),
                            ),
                          ),

                          // Side-by-side Capsule Columns
                          Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(
                                comparisonPoints.length,
                                (idx) {
                                  final point = comparisonPoints[idx];
                                  final isHovered = _hoveredIndex == idx;

                                  return MouseRegion(
                                    onEnter: (_) =>
                                        setState(() => _hoveredIndex = idx),
                                    onExit: (_) =>
                                        setState(() => _hoveredIndex = null),
                                    child: _SideBySideCapsuleColumn(
                                      label: point.month,
                                      purchaseAmount: point.purchaseAmount,
                                      salesAmount: point.salesAmount,
                                      maxScale: maxObserved,
                                      purchaseColor: purchaseColor,
                                      saleColor: saleColor,
                                      isHovered: isHovered,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    required BuildContext context,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryFor(context),
            fontWeight: FontWeight.w600,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  static String _formatAxisLabel(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(0)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(0)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  static List<MonthlyComparisonPointDto> _resolvePointsForRange(
    DashboardSummaryDto summary,
    String range,
  ) {
    switch (range) {
      case '1D':
        if (summary.dailyComparison.isNotEmpty) return summary.dailyComparison;
        return const [
          MonthlyComparisonPointDto(month: '9 AM', salesAmount: 12000, purchaseAmount: 8000),
          MonthlyComparisonPointDto(month: '11 AM', salesAmount: 24000, purchaseAmount: 16000),
          MonthlyComparisonPointDto(month: '1 PM', salesAmount: 38000, purchaseAmount: 22000),
          MonthlyComparisonPointDto(month: '3 PM', salesAmount: 42000, purchaseAmount: 30000),
          MonthlyComparisonPointDto(month: '5 PM', salesAmount: 58000, purchaseAmount: 44000),
          MonthlyComparisonPointDto(month: '7 PM', salesAmount: 76000, purchaseAmount: 52000),
          MonthlyComparisonPointDto(month: '9 PM', salesAmount: 48000, purchaseAmount: 36000),
        ];
      case '1W':
        if (summary.weeklyComparison.isNotEmpty) return summary.weeklyComparison;
        return const [
          MonthlyComparisonPointDto(month: 'Mon', salesAmount: 42000, purchaseAmount: 30000),
          MonthlyComparisonPointDto(month: 'Tue', salesAmount: 58000, purchaseAmount: 45000),
          MonthlyComparisonPointDto(month: 'Wed', salesAmount: 64000, purchaseAmount: 50000),
          MonthlyComparisonPointDto(month: 'Thu', salesAmount: 72000, purchaseAmount: 48000),
          MonthlyComparisonPointDto(month: 'Fri', salesAmount: 88000, purchaseAmount: 60000),
          MonthlyComparisonPointDto(month: 'Sat', salesAmount: 96000, purchaseAmount: 75000),
          MonthlyComparisonPointDto(month: 'Sun', salesAmount: 82000, purchaseAmount: 62000),
        ];
      case '1M':
        return const [
          MonthlyComparisonPointDto(month: 'Week 1', salesAmount: 65000, purchaseAmount: 48000),
          MonthlyComparisonPointDto(month: 'Week 2', salesAmount: 78000, purchaseAmount: 55000),
          MonthlyComparisonPointDto(month: 'Week 3', salesAmount: 92000, purchaseAmount: 70000),
          MonthlyComparisonPointDto(month: 'Week 4', salesAmount: 84000, purchaseAmount: 62000),
        ];
      case '1Y':
      default:
        if (summary.monthlyComparison.isNotEmpty) return summary.monthlyComparison;
        return const [
          MonthlyComparisonPointDto(month: 'Jan', salesAmount: 66000, purchaseAmount: 76000),
          MonthlyComparisonPointDto(month: 'Feb', salesAmount: 42000, purchaseAmount: 65000),
          MonthlyComparisonPointDto(month: 'Mar', salesAmount: 42000, purchaseAmount: 76000),
          MonthlyComparisonPointDto(month: 'Apr', salesAmount: 76000, purchaseAmount: 88000),
          MonthlyComparisonPointDto(month: 'May', salesAmount: 66000, purchaseAmount: 100000),
          MonthlyComparisonPointDto(month: 'Jun', salesAmount: 66000, purchaseAmount: 88000),
          MonthlyComparisonPointDto(month: 'Jul', salesAmount: 54000, purchaseAmount: 76000),
          MonthlyComparisonPointDto(month: 'Aug', salesAmount: 42000, purchaseAmount: 65000),
          MonthlyComparisonPointDto(month: 'Sep', salesAmount: 100000, purchaseAmount: 100000),
          MonthlyComparisonPointDto(month: 'Oct', salesAmount: 65000, purchaseAmount: 76000),
        ];
    }
  }
}

class _YLabel extends StatelessWidget {
  const _YLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.mono.copyWith(
        fontSize: 10,
        color: AppColors.textMutedFor(context),
      ),
    );
  }
}

// ── Side-by-side Capsule Column Widget (Matches Mood Board Screenshot) ────────

class _SideBySideCapsuleColumn extends StatelessWidget {
  const _SideBySideCapsuleColumn({
    required this.label,
    required this.purchaseAmount,
    required this.salesAmount,
    required this.maxScale,
    required this.purchaseColor,
    required this.saleColor,
    required this.isHovered,
  });

  final String label;
  final double purchaseAmount;
  final double salesAmount;
  final double maxScale;
  final Color purchaseColor;
  final Color saleColor;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    // 10 beads corresponds to 100% of maxScale
    final purchaseBeads = maxScale > 0
        ? ((purchaseAmount / maxScale) * 10).clamp(1, 10).toInt()
        : 1;
    final saleBeads = maxScale > 0
        ? ((salesAmount / maxScale) * 10).clamp(1, 10).toInt()
        : 1;

    return Tooltip(
      message: '$label\nTotal Purchase: ₹ ${purchaseAmount.toStringAsFixed(0)}\nTotal Sale: ₹ ${salesAmount.toStringAsFixed(0)}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: purchaseColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Left Column: Total Purchase (Purple beads)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    purchaseBeads,
                    (_) => _bead(purchaseColor),
                  ),
                ),
                const SizedBox(width: 3.5),

                // Right Column: Total Sale (Lavender beads)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    saleBeads,
                    (_) => _bead(saleColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Label
          Text(
            label,
            style: AppTypography.mono.copyWith(
              fontSize: 10.5,
              fontWeight: isHovered ? FontWeight.w800 : FontWeight.w500,
              color: isHovered
                  ? purchaseColor
                  : AppColors.textSecondaryFor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bead(Color color) {
    return Container(
      width: 17,
      height: 11,
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ── Dashed Line Painter ──────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
