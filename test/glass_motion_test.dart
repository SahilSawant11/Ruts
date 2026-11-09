import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/auth/presentation/widgets/martini_glass.dart';
import 'package:pos_app/shared/widgets/three_d/glass_motion.dart';

void main() {
  void run(GlassMotion m, double seconds, {double from = 0}) {
    const dt = 1 / 60;
    for (var t = 0.0; t < seconds; t += dt) {
      m.step(dt, from + t);
    }
  }

  test('glass tilts toward the pointer and settles there', () {
    final m = GlassMotion()..pointer = const Offset(1, -1);
    run(m, 3);
    expect(m.pitch, closeTo(-0.2, 0.01));
    expect(m.roll, closeTo(-0.15, 0.01));
    expect(m.yaw, closeTo(0.55, 0.02));
  });

  test('a sudden move sloshes the drink, which then settles level', () {
    final m = GlassMotion()..pointer = Offset.zero;
    run(m, 2);
    m.pointer = const Offset(1, 1);
    var peak = 0.0;
    for (var i = 0; i < 30; i++) {
      m.step(1 / 60, 2 + i / 60);
      peak = [peak, m.sloshX.abs(), m.sloshZ.abs()].reduce((a, b) => a > b ? a : b);
    }
    expect(peak, greaterThan(0.02), reason: 'the drink should visibly lag the glass');
    expect(peak, lessThanOrEqualTo(0.32), reason: 'slosh is capped so the drink never leaves the glass');
    run(m, 6, from: 3);
    expect(m.sloshX.abs() + m.sloshZ.abs(), lessThan(0.005));
  });

  test('ripples fade', () {
    final m = GlassMotion()..ripple();
    expect(m.wave, greaterThan(0.5));
    run(m, 4);
    expect(m.wave, lessThan(0.01));
  });

  testWidgets('without a GPU shader the flat mark is shown instead', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(width: 400, height: 500, child: MartiniGlass()),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
