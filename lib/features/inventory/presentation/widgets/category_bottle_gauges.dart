import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/three_d/glass_motion.dart';
import '../../data/category_stock.dart';
import '../../data/inventory_providers.dart';

/// "Stock by category": one 3D bottle per category, filled to the share of
/// its products that are healthy. Hover tilts a bottle and the liquid
/// sloshes; clicking filters the stock table to that category.
class CategoryBottleGauges extends ConsumerWidget {
  const CategoryBottleGauges({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(categoryStockProvider).valueOrNull;
    if (stats == null || stats.isEmpty) return const SizedBox.shrink();
    final selected = ref.watch(inventoryCategoryFilterProvider);

    return Container(
      height: 112,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.sm, 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundFor(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderFor(context)),
        boxShadow: AppColors.cardShadowFor(context),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 128,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stock by category', style: AppTypography.label.copyWith(color: AppColors.textPrimaryFor(context))),
                const SizedBox(height: 4),
                Text('Fill shows products above their low-stock level. Click to filter.',
                    style: AppTypography.caption.copyWith(color: AppColors.textMutedFor(context), fontSize: 11, height: 1.35)),
              ],
            ),
          ),
          for (final s in stats)
            Expanded(
              child: _Gauge(
                stat: s,
                selected: selected != null && selected.toLowerCase() == s.category.toLowerCase(),
                onTap: () {
                  final n = ref.read(inventoryCategoryFilterProvider.notifier);
                  n.state = n.state?.toLowerCase() == s.category.toLowerCase() ? null : s.category;
                },
              ),
            ),
        ],
      ),
    );
  }
}

Color _liquidFor(CategoryHealth h) => switch (h) {
      CategoryHealth.good => AppColors.primary,
      CategoryHealth.watch => AppColors.warning,
      CategoryHealth.critical => AppColors.danger,
    };

class _Gauge extends StatelessWidget {
  const _Gauge({required this.stat, required this.selected, required this.onTap});

  final CategoryStock stat;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = AppTypography.caption.copyWith(color: AppColors.textMutedFor(context), fontSize: 11);
    final issues = stat.low + stat.out;
    return Tooltip(
      waitDuration: const Duration(milliseconds: 400),
      message: '${stat.category}: ${stat.healthy} of ${stat.products} products healthy'
          '${stat.low > 0 ? ' · ${stat.low} low' : ''}${stat.out > 0 ? ' · ${stat.out} out' : ''}'
          ' · ${Money.group(stat.bottles, decimals: 0)} bottles\nClick to filter the table',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected ? AppColors.primarySoftFor(context) : Colors.transparent,
          ),
          child: Column(
            children: [
              Expanded(child: BottleGauge(fill: stat.fill, liquid: _liquidFor(stat.health))),
              Text(stat.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.textPrimaryFor(context), height: 1.2)),
              Text(
                issues == 0 ? '${stat.products} all healthy' : '${stat.healthy}/${stat.products} healthy',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted.copyWith(height: 1.2),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// ── the bottle ──────────────────────────────────────────────────────────

Future<ui.FragmentProgram?>? _program;
Future<ui.FragmentProgram?> _loadBottle() => _program ??= ui.FragmentProgram.fromAsset('shaders/bottle.frag')
    .then<ui.FragmentProgram?>((p) => p)
    .catchError((Object _) => null);

/// One 3D bottle filled to [fill] (0..1) with [liquid]. It fills up when it
/// first appears and animates only while hovered or settling, so a row of
/// them costs nothing when idle. Falls back to a flat drawing if the GPU
/// shader can't load.
class BottleGauge extends StatefulWidget {
  const BottleGauge({super.key, required this.fill, required this.liquid});

  final double fill;
  final Color liquid;

  @override
  State<BottleGauge> createState() => _BottleGaugeState();
}

class _BottleGaugeState extends State<BottleGauge> with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  bool _failed = false;
  late final Ticker _ticker = createTicker(_tick);
  final _motion = GlassMotion(idleSway: false);
  Duration _last = Duration.zero;
  double _shown = 0; // displayed level, eases toward widget.fill

  @override
  void initState() {
    super.initState();
    _loadBottle().then((p) {
      if (!mounted) return;
      setState(() {
        if (p == null) {
          _failed = true;
        } else {
          _shader = p.fragmentShader();
        }
      });
      _wake();
    });
  }

  @override
  void didUpdateWidget(BottleGauge old) {
    super.didUpdateWidget(old);
    if (old.fill != widget.fill) _wake();
  }

  void _wake() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero ? 1 / 60 : ((now - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = now;
    final before = _shown;
    _shown += (widget.fill - _shown) * (1 - math.exp(-4.0 * dt));
    if ((widget.fill - _shown).abs() < 0.002) _shown = widget.fill;
    _motion.step(dt, now.inMicroseconds / 1e6);
    setState(() {});
    if (_motion.isSettled && _shown == widget.fill && before == _shown) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.backgroundFor(context);
    final glass = AppColors.textPrimaryFor(context);
    final shader = _shader;
    if (_failed || shader == null) {
      return CustomPaint(
        size: Size.infinite,
        painter: _FlatBottlePainter(level: _failed ? _shown : 0, liquid: widget.liquid, glass: glass),
      );
    }
    return LayoutBuilder(builder: (context, c) {
      final size = c.biggest;
      Offset norm(Offset p) => Offset(
            (p.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
            (p.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
          );
      return MouseRegion(
        onHover: (e) {
          _motion.pointer = norm(e.localPosition);
          _wake();
        },
        onExit: (_) {
          _motion.pointer = null;
          _wake();
        },
        child: RepaintBoundary(
          child: CustomPaint(
            size: size,
            painter: _BottlePainter(shader, _motion, _shown, bg, glass, widget.liquid),
          ),
        ),
      );
    });
  }
}

class _BottlePainter extends CustomPainter {
  _BottlePainter(this.shader, this.m, this.level, this.bg, this.glass, this.liquid);

  final ui.FragmentShader shader;
  final GlassMotion m;
  final double level;
  final Color bg, glass, liquid;

  @override
  void paint(Canvas canvas, Size size) {
    var i = 0;
    void f(double v) => shader.setFloat(i++, v);
    f(size.width);
    f(size.height);
    f(m.time);
    // Bottles tilt less than the martini; mostly a turn and a lean.
    f(m.pitch * 0.6);
    f(m.yaw);
    f(m.roll * 0.8);
    f(m.sloshX);
    f(m.sloshZ);
    f(0.02 * m.wave);
    f(level);
    for (final c in [bg, glass, liquid]) {
      f(c.r);
      f(c.g);
      f(c.b);
    }
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Flat fallback (and what tests see): outline bottle with a filled level.
class _FlatBottlePainter extends CustomPainter {
  _FlatBottlePainter({required this.level, required this.liquid, required this.glass});

  final double level;
  final Color liquid, glass;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height * 0.86;
    final w = h * 0.42;
    final left = (size.width - w) / 2;
    final top = (size.height - h) / 2;
    final neckW = w * 0.32;
    final bodyTop = top + h * 0.42;
    final path = Path()
      ..moveTo(left + (w - neckW) / 2, top)
      ..lineTo(left + (w + neckW) / 2, top)
      ..lineTo(left + (w + neckW) / 2, top + h * 0.22)
      ..quadraticBezierTo(left + w, top + h * 0.3, left + w, bodyTop)
      ..lineTo(left + w, top + h - 6)
      ..quadraticBezierTo(left + w, top + h, left + w - 6, top + h)
      ..lineTo(left + 6, top + h)
      ..quadraticBezierTo(left, top + h, left, top + h - 6)
      ..lineTo(left, bodyTop)
      ..quadraticBezierTo(left, top + h * 0.3, left + (w - neckW) / 2, top + h * 0.22)
      ..close();
    final fillTop = top + h - (h - (bodyTop - top) - 4) * level.clamp(0.0, 1.0) - 4;
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(Rect.fromLTRB(left, fillTop, left + w, top + h), Paint()..color = liquid);
    canvas.restore();
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = glass.withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(covariant _FlatBottlePainter old) =>
      old.level != level || old.liquid != liquid || old.glass != glass;
}
