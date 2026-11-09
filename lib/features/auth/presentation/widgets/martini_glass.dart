import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  final _motion = MartiniMotion();
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

/// The glass's motion: springs toward where the pointer is, with the drink
/// sloshing from the glass's angular acceleration. Pure Dart, so it can be
/// tested without a GPU.
class MartiniMotion {
  /// Pointer over the glass in -1..1 (x right, y down), or null if away.
  Offset? pointer;

  double pitch = 0, yaw = 0, roll = 0;
  double _pitchV = 0, _yawV = 0, _rollV = 0;
  double _spin = 0; // extra yaw from dragging
  double sloshX = 0, sloshZ = 0;
  double _sloshXV = 0, _sloshZV = 0;
  double wave = 0;
  double time = 0;

  static const _k = 38.0; // glass spring stiffness
  static const _c = 10.5; // glass damping (just under critical)
  static const _ks = 70.0; // drink stiffness
  static const _cs = 2.6; // drink damping: low, so it wobbles
  static const _maxSlosh = 0.32;

  void drag(double dxFraction) {
    _spin += dxFraction * math.pi * 1.6;
    wave = math.min(1.0, wave + dxFraction.abs() * 6);
  }

  void ripple() => wave = math.min(1.0, wave + 0.6);

  void step(double dt, double t) {
    time = t;
    if (dt <= 0) return;
    final p = pointer;
    // Where the glass wants to be: tilted toward the pointer, or a slow sway.
    final tPitch = p == null ? 0.06 * math.sin(t * 0.7) : p.dy * 0.2;
    final tRoll = p == null ? 0.05 * math.sin(t * 0.53) : -p.dx * 0.15;
    final tYaw = (p == null ? 0.35 * math.sin(t * 0.31) : p.dx * 0.55) + _spin;
    _spin *= math.exp(-0.35 * dt); // drift back to facing front

    final pitchA = _k * (tPitch - pitch) - _c * _pitchV;
    final rollA = _k * (tRoll - roll) - _c * _rollV;
    final yawA = _k * (tYaw - yaw) - _c * _yawV;
    _pitchV += pitchA * dt;
    _rollV += rollA * dt;
    _yawV += yawA * dt;
    pitch += _pitchV * dt;
    roll += _rollV * dt;
    yaw += _yawV * dt;

    // The drink lags the glass: angular acceleration pushes its surface.
    final sxA = -_ks * sloshX - _cs * _sloshXV + 0.5 * rollA;
    final szA = -_ks * sloshZ - _cs * _sloshZV - 0.5 * pitchA;
    _sloshXV += sxA * dt;
    _sloshZV += szA * dt;
    sloshX = (sloshX + _sloshXV * dt).clamp(-_maxSlosh, _maxSlosh);
    sloshZ = (sloshZ + _sloshZV * dt).clamp(-_maxSlosh, _maxSlosh);

    wave *= math.exp(-1.8 * dt);
  }
}

class _MartiniPainter extends CustomPainter {
  _MartiniPainter(this.shader, this.m, this.bg, this.fg);

  final ui.FragmentShader shader;
  final MartiniMotion m;
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
