import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/widgets/three_d/glass_motion.dart';

/// The Caskly martini, in 3D, for the login screen.
///
/// Moving the mouse over it tilts the glass and the drink sloshes; dragging
/// spins it and swirls the drink; a click sends a ripple. Left alone it
/// sways gently. Drawn by `shaders/martini.frag`; if the GPU shader can't
/// load (very old graphics drivers), the flat mark is shown instead.
class MartiniGlass extends StatefulWidget {
  const MartiniGlass({super.key, this.background = const Color(0xFF141218), this.foreground = const Color(0xFFF3EFE6)});

  final Color background;
  final Color foreground;

  @override
  State<MartiniGlass> createState() => _MartiniGlassState();
}

Future<ui.FragmentProgram?>? _program;

Future<ui.FragmentProgram?> _loadProgram() => _program ??= ui.FragmentProgram.fromAsset('shaders/martini.frag')
    .then<ui.FragmentProgram?>((p) => p)
    .catchError((Object _) => null);

class _MartiniGlassState extends State<MartiniGlass> with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  bool _failed = false;
  late final Ticker _ticker;
  final _motion = GlassMotion();
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _loadProgram().then((p) {
      if (!mounted) return;
      setState(() {
        if (p == null) {
          _failed = true;
        } else {
          _shader = p.fragmentShader();
          _ticker.start();
        }
      });
    });
  }

  void _tick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = now;
    setState(() => _motion.step(dt, now.inMicroseconds / 1e6));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    super.dispose();
  }

  Offset _norm(Offset local, Size size) => Offset(
        (local.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
        (local.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
      );

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
        child: SvgPicture.asset('assets/branding/caskly_mark_light.svg', width: 260, height: 260),
      );
    }
    final shader = _shader;
    if (shader == null) return const SizedBox.expand();
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      return MouseRegion(
        cursor: SystemMouseCursors.grab,
        onHover: (e) => _motion.pointer = _norm(e.localPosition, size),
        onExit: (_) => _motion.pointer = null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _motion.ripple(),
          onPanUpdate: (d) {
            _motion.pointer = _norm(d.localPosition, size);
            _motion.drag(d.delta.dx / size.width);
          },
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: _MartiniPainter(shader, _motion, widget.background, widget.foreground),
            ),
          ),
        ),
      );
    });
  }
}

class _MartiniPainter extends CustomPainter {
  _MartiniPainter(this.shader, this.m, this.bg, this.fg);

  final ui.FragmentShader shader;
  final GlassMotion m;
  final Color bg;
  final Color fg;

  @override
  void paint(Canvas canvas, Size size) {
    var i = 0;
    void f(double v) => shader.setFloat(i++, v);
    f(size.width);
    f(size.height);
    f(m.time);
    f(m.pitch);
    f(m.yaw);
    f(m.roll);
    f(m.sloshX);
    f(m.sloshZ);
    f(0.022 * m.wave);
    f(bg.r);
    f(bg.g);
    f(bg.b);
    f(fg.r);
    f(fg.g);
    f(fg.b);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
