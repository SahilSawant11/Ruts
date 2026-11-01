import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/format/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
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
  ConsumerState<SalesPurchaseCapsuleCard> createState() => _SalesPurchaseCapsuleCardState();
}

class _SalesPurchaseCapsuleCardState extends ConsumerState<SalesPurchaseCapsuleCard> {
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
                  color: isDark ? purchaseColor.withValues(alpha: 0.20) : const Color(0xFFF1EEFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const AppIcon(
                  AppIcons.tag,
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? (isDark ? Colors.white : const Color(0xFF16161F)) : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          range,
                          style: AppTypography.mono.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                isSelected ? (isDark ? Colors.black : Colors.white) : AppColors.textMutedFor(context),
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

              // Scale: round the largest bar up to a nice number so the five
              // gridlines read 1L, 2L, 3L… instead of 1.2L, 2.4L…
              double peak = 0;
              for (final p in comparisonPoints) {
                if (p.salesAmount > peak) peak = p.salesAmount;
                if (p.purchaseAmount > peak) peak = p.purchaseAmount;
              }
              final maxObserved = _niceCeil(peak);

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
                          const _YLabel('0'),
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
                                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E5EB),
                                ),
                              ),
                            ),
                          ),

                          // Side-by-side Capsule Columns (Expanded for responsive width)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(
                                comparisonPoints.length,
                                (idx) {
                                  final point = comparisonPoints[idx];
                                  final isHovered = _hoveredIndex == idx;

                                  return Expanded(
                                    child: MouseRegion(
                                      onEnter: (_) => setState(() => _hoveredIndex = idx),
                                      onExit: (_) => setState(() => _hoveredIndex = null),
                                      child: _SideBySideCapsuleColumn(
                                        label: point.month,
                                        purchaseAmount: point.purchaseAmount,
                                        salesAmount: point.salesAmount,
                                        maxScale: maxObserved,
                                        purchaseColor: purchaseColor,
                                        saleColor: saleColor,
                                        isHovered: isHovered,
                                        isDark: isDark,
                                      ),
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

  static String _formatAxisLabel(double v) => v == 0 ? '0' : Money.compact(v, symbol: false);

  /// Real data only — an empty store shows empty bars, never sample numbers.
  static List<MonthlyComparisonPointDto> _resolvePointsForRange(
    DashboardSummaryDto summary,
    String range,
  ) {
    return switch (range) {
      '1D' => summary.dailyComparison,
      '1W' => summary.weeklyComparison,
      '1M' => summary.last4WeeksComparison,
      _ => summary.monthlyComparison,
    };
  }

  /// Axis maximum = 5 gridline steps, where the step is a "nice" number
  /// (1, 1.5, 2, 2.5, 3, 4, 5, 6, 8 × 10^n) just big enough for [peak].
  static double _niceCeil(double peak) {
    if (peak <= 0) return 5000;
    final raw = peak / 5;
    final exp = (math.log(raw) / math.ln10).floor();
    final base = math.pow(10, exp).toDouble();
    for (final m in const [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0]) {
      if (raw <= m * base) return m * base * 5;
    }
    return 50 * base;
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
    required this.isDark,
  });

  final String label;
  final double purchaseAmount;
  final double salesAmount;
  final double maxScale;
  final Color purchaseColor;
  final Color saleColor;
  final bool isHovered;
  final bool isDark;

  static const double beadWidth = 22.0;
  static const double beadHeight = 11.0;

  @override
  Widget build(BuildContext context) {
    // 0 value records must have 0 beads so they sit on 0K baseline
    final purchaseBeads =
        (purchaseAmount > 0 && maxScale > 0) ? ((purchaseAmount / maxScale) * 10).round().clamp(1, 10) : 0;
    final saleBeads = (salesAmount > 0 && maxScale > 0) ? ((salesAmount / maxScale) * 10).round().clamp(1, 10) : 0;

    return Tooltip(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E212E) : const Color(0xFF161822),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      richMessage: TextSpan(
        children: [
          TextSpan(
            text: '$label\n',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
          TextSpan(
            text: '● Total Purchase: ',
            style: TextStyle(
              color: purchaseColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          TextSpan(
            text: '${Money.inr(purchaseAmount, decimals: 0)}\n',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const TextSpan(
            text: '● Total Sale: ',
            style: TextStyle(
              color: Color(0xFFC7BFF8),
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          TextSpan(
            text: Money.inr(salesAmount, decimals: 0),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Shrink beads to the slot width (12 monthly slots are narrow at 1366px).
          LayoutBuilder(builder: (context, constraints) {
            final beadW = constraints.maxWidth.isFinite
                ? ((constraints.maxWidth - 4 - 3.5) / 2).clamp(4.0, beadWidth)
                : beadWidth;
            return AnimatedContainer(
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
                    children: purchaseBeads > 0
                        ? List.generate(
                            purchaseBeads,
                            (_) => _bead(purchaseColor, beadW),
                          )
                        : [_emptyBase(purchaseColor, beadW)],
                  ),
                  const SizedBox(width: 3.5),

                  // Right Column: Total Sale (Lavender beads)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: saleBeads > 0
                        ? List.generate(
                            saleBeads,
                            (_) => _bead(saleColor, beadW),
                          )
                        : [_emptyBase(saleColor, beadW)],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),

          // Label
          Text(
            label,
            style: AppTypography.mono.copyWith(
              fontSize: 10.5,
              fontWeight: isHovered ? FontWeight.w800 : FontWeight.w500,
              color: isHovered ? purchaseColor : AppColors.textSecondaryFor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bead(Color color, double width) {
    return Container(
      width: width,
      height: beadHeight,
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _emptyBase(Color color, double width) {
    return Container(
      width: width,
      height: 2.5,
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(2),
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
