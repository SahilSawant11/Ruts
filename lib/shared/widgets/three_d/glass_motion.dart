import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Motion for the 3D glassware (login martini, inventory bottles): the
/// vessel springs toward where the pointer is, and the liquid sloshes from
/// the vessel's angular acceleration. Pure Dart, so it is testable without
/// a GPU.
///
/// [idleSway] keeps a slow sway going when the pointer is away (login);
/// without it the vessel comes to rest and [isSettled] turns true so the
/// caller can stop its ticker (inventory gauges).
class GlassMotion {
  GlassMotion({this.idleSway = true});

  final bool idleSway;

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
    final sway = idleSway ? 1.0 : 0.0;
    final tPitch = p == null ? sway * 0.06 * math.sin(t * 0.7) : p.dy * 0.2;
    final tRoll = p == null ? sway * 0.05 * math.sin(t * 0.53) : -p.dx * 0.15;
    final tYaw = (p == null ? sway * 0.35 * math.sin(t * 0.31) : p.dx * 0.55) + _spin;
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

  /// At rest with nothing pulling it: safe to stop animating.
  bool get isSettled {
    if (pointer != null || idleSway) return false;
    const e = 0.002;
    return [pitch, roll, yaw, _spin, sloshX, sloshZ, _pitchV, _rollV, _yawV, _sloshXV, _sloshZV, wave]
        .every((v) => v.abs() < e);
  }
}
