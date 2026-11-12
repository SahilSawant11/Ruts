import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/data/figure.dart';
import '../../data/dashboard_providers.dart';
import '../../data/models/dashboard_summary_dto.dart';

enum SalesRange {
  day('1D', 'Today'),
  week('1W', 'Last 7 days'),
  month('1M', 'Last 4 weeks'),
  year('1Y', 'Last 12 months');

  const SalesRange(this.label, this.description);
  final String label;
  final String description;
}

/// Sales & purchases over time on the ink card: sales as a smooth line
/// with a gold gradient stroke and a soft fill, purchases as a quiet thin
/// line, callouts at the peak and the latest point, and a hover crosshair.
class SalesPurchaseLineCard extends ConsumerStatefulWidget {
  const SalesPurchaseLineCard({super.key});

  @override
  ConsumerState<SalesPurchaseLineCard> createState() => _SalesPurchaseLineCardState();
}

class _SalesPurchaseLineCardState extends ConsumerState<SalesPurchaseLineCard> {
  SalesRange _range = SalesRange.year;
  int? _hover;

  static const _gold = AppColors.primary;
  static const _purchase = AppColors.cream;

  static List<MonthlyComparisonPointDto> pointsFor(DashboardSummaryDto s, SalesRange r) => switch (r) {
        SalesRange.day => s.dailyComparison,
        SalesRange.week => s.weeklyComparison,
        SalesRange.month => s.last4WeeksComparison,
        SalesRange.year => s.monthlyComparison,
      };

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(dashboardSummaryProvider);
    final muted = AppColors.cream.withValues(alpha: 0.55);

    return LayoutBuilder(builder: (context, constraints) {
      final bounded = constraints.hasBoundedHeight;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: const Color(0xFF2C2933)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: summary.when(
          loading: () => const SizedBox(height: 330, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (e, _) => SizedBox(
            height: 330,
            child: Center(child: Text('Could not load chart data', style: AppTypography.body.copyWith(color: muted))),
          ),
          data: (s) {
            final points = pointsFor(s, _range);
            // Purchases carry a date but no time, so an hourly purchase line
            // would be a fake spike; on 1D they are shown as a total only.
            final showPurchaseLine = _range != SalesRange.day;
            final sales = points.fold<double>(0, (t, p) => t + p.salesAmount);
            final purchases = points.fold<double>(0, (t, p) => t + p.purchaseAmount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sales & Purchase',
                              style: AppTypography.sectionTitle
                                  .copyWith(color: AppColors.cream, fontWeight: FontWeight.w700, fontSize: 17)),
                          const SizedBox(height: 2),
                          Text(_range.description, style: AppTypography.caption.copyWith(color: muted)),
                        ],
                      ),
                    ),
                    PillTabs<SalesRange>(
                      values: SalesRange.values,
                      selected: _range,
                      label: (r) => r.label,
                      onSelected: (r) => setState(() {
                        _range = r;
                        _hover = null;
                      }),
                      onInk: true,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xl,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _Total(label: 'Sales', value: sales, dot: _gold),
                    _Total(label: 'Purchases', value: purchases, dot: _purchase),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Fills the card when the dashboard gives it a height (to line
                // up with the card beside it); 210px tall otherwise.
                Flexible(
                  flex: bounded ? 1 : 0,
                  child: SizedBox(
                    height: bounded ? null : 210,
                    child: points.isEmpty
                        ? Center(child: Text('No data yet', style: AppTypography.body.copyWith(color: muted)))
                        : LayoutBuilder(builder: (context, c) {
                            final chart = _ChartGeometry(points, c.biggest, showPurchases: showPurchaseLine);
                            return MouseRegion(
                              onHover: (e) => setState(() => _hover = chart.nearestIndex(e.localPosition.dx)),
                              onExit: (_) => setState(() => _hover = null),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CustomPaint(
                                    size: c.biggest,
                                    painter: _LinePainter(chart, hover: _hover, labelStyle: _axisStyle(context)),
                                  ),
                                  ..._callouts(chart),
                                  if (_hover != null) _tooltip(chart, _hover!, showPurchaseLine),
                                ],
                              ),
                            );
                          }),
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  TextStyle _axisStyle(BuildContext context) =>
      AppTypography.caption.copyWith(color: AppColors.cream.withValues(alpha: 0.45), fontSize: 10.5);

  /// Small labels at the peak and the latest point (one if they coincide).
  List<Widget> _callouts(_ChartGeometry g) {
    if (g.points.every((p) => p.salesAmount <= 0)) return const [];
    final last = g.points.length - 1;
    final indices = {g.peakIndex, last};
    return [
      for (final i in indices)
        Positioned(
          left: (g.x(i) - 60).clamp(0.0, g.size.width - 120),
          top: (g.ySales(i) - 34).clamp(0.0, g.size.height),
          width: 120,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: ShapeDecoration(
                color: AppColors.inkSoft,
                shape: StadiumBorder(side: BorderSide(color: _gold.withValues(alpha: 0.35))),
              ),
              child: Text(
                '${i == g.peakIndex && i != last ? '↑ ' : ''}${Money.compact(g.points[i].salesAmount)} · ${g.points[i].month}',
                style:
                    AppTypography.caption.copyWith(color: AppColors.cream, fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _tooltip(_ChartGeometry g, int i, bool showPurchases) {
    final p = g.points[i];
    const w = 150.0;
    final left = g.x(i) + 12 + w > g.size.width ? g.x(i) - 12 - w : g.x(i) + 12;
    return Positioned(
      left: left,
      top: 4,
      width: w,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.month, style: AppTypography.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            _tipRow('Sales', Money.inr(p.salesAmount, decimals: 0), _gold),
            if (showPurchases) _tipRow('Purchases', Money.inr(p.purchaseAmount, decimals: 0), AppColors.ink),
          ],
        ),
      ),
    );
  }

  Widget _tipRow(String label, String value, Color dot) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: AppTypography.caption.copyWith(color: AppColors.ink))),
            Text(value, style: AppTypography.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value, required this.dot});
  final String label;
  final double value;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.cream.withValues(alpha: 0.6))),
        ]),
        const SizedBox(height: 4),
        Figure(Money.inr(value, decimals: 0, symbol: false), prefix: '₹', size: 32, color: AppColors.cream),
      ],
    );
  }
}

/// Maps data to pixels: left gutter for the y labels, bottom for x labels.
class _ChartGeometry {
  _ChartGeometry(this.points, this.size, {required this.showPurchases}) {
    var peak = 0.0;
    for (final p in points) {
      peak = math.max(peak, p.salesAmount);
      if (showPurchases) peak = math.max(peak, p.purchaseAmount);
    }
    maxY = niceCeil(peak);
    var best = 0;
    for (var i = 1; i < points.length; i++) {
      if (points[i].salesAmount > points[best].salesAmount) best = i;
    }
    peakIndex = best;
  }

  final List<MonthlyComparisonPointDto> points;
  final Size size;
  final bool showPurchases;
  late final double maxY;
  late final int peakIndex;

  static const left = 44.0, bottom = 24.0, top = 30.0, right = 12.0;

  Rect get plot => Rect.fromLTRB(left, top, size.width - right, size.height - bottom);

  double x(int i) => points.length == 1 ? plot.center.dx : plot.left + plot.width * i / (points.length - 1);
  double y(double v) => plot.bottom - plot.height * (v / maxY).clamp(0.0, 1.0);
  double ySales(int i) => y(points[i].salesAmount);

  int nearestIndex(double dx) {
    if (points.length == 1) return 0;
    final t = ((dx - plot.left) / plot.width).clamp(0.0, 1.0);
    return (t * (points.length - 1)).round();
  }

  /// Axis maximum = 4 gridline steps of a "nice" size just above [peak].
  static double niceCeil(double peak) {
    if (peak <= 0) return 4000;
    final raw = peak / 4;
    final exp = (math.log(raw) / math.ln10).floor();
    final base = math.pow(10, exp).toDouble();
    for (final m in const [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0]) {
      if (raw <= m * base) return m * base * 4;
    }
    return 40 * base;
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.g, {required this.hover, required this.labelStyle});

  final _ChartGeometry g;
  final int? hover;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = g.plot;

    // Grid + y labels.
    final grid = Paint()
      ..color = AppColors.cream.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var k = 0; k <= 4; k++) {
      final v = g.maxY * k / 4;
      final yy = g.y(v);
      _dashed(canvas, Offset(plot.left, yy), Offset(plot.right, yy), grid);
      _text(canvas, v == 0 ? '0' : Money.compact(v, symbol: false), Offset(0, yy - 7), labelStyle);
    }
    // X labels (thinned so they never collide).
    final every = (g.points.length / 8).ceil().clamp(1, 99);
    for (var i = 0; i < g.points.length; i += every) {
      final tp = _layout(g.points[i].month, labelStyle);
      tp.paint(canvas, Offset(g.x(i) - tp.width / 2, plot.bottom + 8));
    }

    final salesPts = [for (var i = 0; i < g.points.length; i++) Offset(g.x(i), g.ySales(i))];

    // Purchases: thin, quiet.
    if (g.showPurchases) {
      final pPts = [for (var i = 0; i < g.points.length; i++) Offset(g.x(i), g.y(g.points[i].purchaseAmount))];
      canvas.drawPath(
        _smooth(pPts),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..color = AppColors.cream.withValues(alpha: 0.5),
      );
    }

    // Sales: soft fill, then the gradient stroke on top.
    final line = _smooth(salesPts);
    final fill = Path.from(line)
      ..lineTo(salesPts.last.dx, plot.bottom)
      ..lineTo(salesPts.first.dx, plot.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, plot.top),
          Offset(0, plot.bottom),
          [AppColors.primary.withValues(alpha: 0.28), AppColors.primary.withValues(alpha: 0.0)],
        ),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = ui.Gradient.linear(
          Offset(plot.left, 0),
          Offset(plot.right, 0),
          const [Color(0xFFC2550A), AppColors.primary, Color(0xFFF8D88E)],
          const [0.0, 0.6, 1.0],
        ),
    );

    // Markers: dashed drop line + dot at the peak and the latest point.
    final drop = Paint()
      ..color = AppColors.cream.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    if (g.points.any((p) => p.salesAmount > 0)) {
      for (final i in {g.peakIndex, g.points.length - 1}) {
        _dashed(canvas, Offset(g.x(i), g.ySales(i)), Offset(g.x(i), plot.bottom), drop);
        _dot(canvas, salesPts[i]);
      }
    }

    // Hover crosshair.
    if (hover != null) {
      final i = hover!;
      canvas.drawLine(
        Offset(g.x(i), plot.top),
        Offset(g.x(i), plot.bottom),
        Paint()
          ..color = AppColors.cream.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );
      _dot(canvas, salesPts[i]);
    }
  }

  void _dot(Canvas canvas, Offset c) {
    canvas.drawCircle(c, 5.5, Paint()..color = AppColors.ink);
    canvas.drawCircle(c, 4, Paint()..color = AppColors.primary);
  }

  /// Monotone cubic (Fritsch–Carlson): smooth, but never overshoots below
  /// zero or above a peak the data didn't reach.
  static Path _smooth(List<Offset> p) {
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    if (p.length < 3) {
      for (final q in p.skip(1)) {
        path.lineTo(q.dx, q.dy);
      }
      return path;
    }
    final n = p.length;
    final d = List<double>.generate(n - 1, (i) => (p[i + 1].dy - p[i].dy) / (p[i + 1].dx - p[i].dx));
    final m = List<double>.filled(n, 0);
    m[0] = d[0];
    m[n - 1] = d[n - 2];
    for (var i = 1; i < n - 1; i++) {
      m[i] = d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2;
    }
    for (var i = 0; i < n - 1; i++) {
      if (d[i] == 0) {
        m[i] = 0;
        m[i + 1] = 0;
        continue;
      }
      final a = m[i] / d[i], b = m[i + 1] / d[i];
      final s = a * a + b * b;
      if (s > 9) {
        final t = 3 / math.sqrt(s);
        m[i] = t * a * d[i];
        m[i + 1] = t * b * d[i];
      }
    }
    for (var i = 0; i < n - 1; i++) {
      final h = (p[i + 1].dx - p[i].dx) / 3;
      path.cubicTo(
          p[i].dx + h, p[i].dy + m[i] * h, p[i + 1].dx - h, p[i + 1].dy - m[i + 1] * h, p[i + 1].dx, p[i + 1].dy);
    }
    return path;
  }

  static void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0, gap = 4.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    for (var t = 0.0; t < total; t += dash + gap) {
      canvas.drawLine(a + dir * t, a + dir * math.min(t + dash, total), paint);
    }
  }

  static TextPainter _layout(String s, TextStyle style) =>
      TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();

  static void _text(Canvas canvas, String s, Offset at, TextStyle style) => _layout(s, style).paint(canvas, at);

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.g.points != g.points || old.hover != hover || old.g.size != g.size;
}
