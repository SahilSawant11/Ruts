// Dev-only: renders the login screen's 3D martini as a frame sequence for
// the promo film, driven by a scripted cursor at exactly 30 fps.
//
//   flutter run -d macos -t tooling/promo_martini_frames.dart
//
// Writes (to the app's sandboxed caches folder, printed at the end):
//   login.png          the full login screen, 3840x2160, glass at rest
//   martini/0000.png…  the glass panel only, one PNG per video frame
//   martini/path.json  cursor position per frame in 1920x1080 screen
//                      coordinates (null = cursor not over the glass)
// Copy them to caskly-promo/public/login/.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/auth/presentation/screens/login_screen.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/shared/widgets/three_d/glass_motion.dart';

const _fps = 30;
const _frames = 165;
const _scale = 2.0; // render at 2x for 4K-sharp frames
// The login screen at 1920x1080: the glass panel is the left 46%.
const _panelW = 1920 * 46 / 100;
const _panelH = 1080.0;

/// Scripted cursor in 1920x1080 screen coordinates (null = off the glass).
Offset? cursorAt(int f) {
  Offset lerp(Offset a, Offset b, double t) {
    final e = t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2; // ease in-out
    return Offset.lerp(a, b, e.toDouble())!;
  }

  const enter = Offset(1150, 760); // comes in from the form side
  const a = Offset(520, 470); // over the bowl
  const b = Offset(250, 330); // up-left: tilts the glass back
  const c = Offset(640, 720); // down-right: tilts it forward
  const exit = Offset(1210, 690); // back to the "Enter Caskly" button
  if (f < 24) return null;
  if (f < 60) return lerp(enter, a, (f - 24) / 36);
  if (f < 84) return lerp(a, b, (f - 60) / 24);
  if (f < 112) return lerp(b, c, (f - 84) / 28);
  if (f < 140) return lerp(c, exit, (f - 112) / 28);
  return exit;
}

final _loginKey = GlobalKey();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final out = '${(await getTemporaryDirectory()).path}/promo_login';
  await Directory('$out/martini').create(recursive: true);

  // 1. The full login screen once, for the window around the glass.
  final db = AppDatabase(NativeDatabase.memory());
  runApp(ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: 1920, maxWidth: 1920, minHeight: 1080, maxHeight: 1080,
        child: RepaintBoundary(
          key: _loginKey,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(1920, 1080), devicePixelRatio: 1),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              home: const LoginScreen(),
            ),
          ),
        ),
      ),
    ),
  ));
  for (var i = 0; i < 90; i++) {
    WidgetsBinding.instance.scheduleForcedFrame();
    await WidgetsBinding.instance.endOfFrame.timeout(const Duration(milliseconds: 60), onTimeout: () {});
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
  final shot = await (_loginKey.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage(pixelRatio: _scale);
  await _png(shot, '$out/login.png');

  // 2. The glass, frame by frame, with fixed time steps.
  final program = await ui.FragmentProgram.fromAsset('shaders/martini.frag');
  final shader = program.fragmentShader();
  final motion = GlassMotion();
  final path = <List<double>?>[];
  const sub = 4; // physics substeps per video frame
  final w = (_panelW * _scale).round(), h = (_panelH * _scale).round();
  for (var f = 0; f < _frames; f++) {
    final cur = cursorAt(f);
    path.add(cur == null ? null : [cur.dx, cur.dy]);
    motion.pointer = (cur == null || cur.dx > _panelW)
        ? null
        : Offset((cur.dx / _panelW * 2 - 1).clamp(-1.0, 1.0), (cur.dy / _panelH * 2 - 1).clamp(-1.0, 1.0));
    for (var s = 0; s < sub; s++) {
      final t = (f * sub + s + 1) / (_fps * sub);
      motion.step(1 / (_fps * sub), t);
    }
    var i = 0;
    void u(double v) => shader.setFloat(i++, v);
    u(w.toDouble());
    u(h.toDouble());
    u(motion.time);
    u(motion.pitch);
    u(motion.yaw);
    u(motion.roll);
    u(motion.sloshX);
    u(motion.sloshZ);
    u(0.022 * motion.wave);
    for (final v in const [0x14 / 255, 0x12 / 255, 0x18 / 255, 0xF3 / 255, 0xEF / 255, 0xE6 / 255]) {
      u(v);
    }
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..shader = shader);
    final img = await rec.endRecording().toImage(w, h);
    await _png(img, '$out/martini/${f.toString().padLeft(4, '0')}.png');
    img.dispose();
  }
  await File('$out/martini/path.json').writeAsString(jsonEncode({
    'fps': _fps,
    'frames': _frames,
    'panel': [_panelW, _panelH],
    'cursor': path,
  }));
  // ignore: avoid_print
  print('PROMO_FRAMES_DONE $out');
  exit(0);
}

Future<void> _png(ui.Image img, String path) async {
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  await File(path).writeAsBytes(bytes!.buffer.asUint8List());
}
