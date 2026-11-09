// A stock gauge for the inventory screen: a 3D bottle whose liquid level
// is the share of a category's products that are healthy.
//
// Same language as the login martini: a faint glass bottle, the liquid
// flat and nearly unshaded, on the card's own background. Raymarched
// signed distance fields, surface of revolution around local y. SkSL-safe
// (no transpose, no non-constant loop bounds) for Windows' Skia renderer.
#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;     // canvas size, pixels
uniform float uTime;    // seconds
uniform vec3 uRot;      // pitch, yaw, roll (radians)
uniform vec2 uSlosh;    // liquid surface tilt, world (x, z)
uniform float uWave;    // ripple amplitude
uniform float uLevel;   // fill 0..1
uniform vec3 uBg;       // card background
uniform vec3 uGlass;    // glass edge colour
uniform vec3 uLiquid;   // liquid colour

out vec4 fragColor;

const float RB = 0.40;       // body radius
const float BODY_TOP = 1.02; // where the shoulder starts
const float T = 0.022;       // wall half-thickness
const vec3 CENTER = vec3(0.0, 0.88, 0.0);

vec3 gLiqN = vec3(0.0, 1.0, 0.0);

mat3 rotX(float a) { float c = cos(a), s = sin(a); return mat3(1.0, 0.0, 0.0, 0.0, c, s, 0.0, -s, c); }
mat3 rotY(float a) { float c = cos(a), s = sin(a); return mat3(c, 0.0, -s, 0.0, 1.0, 0.0, s, 0.0, c); }
mat3 rotZ(float a) { float c = cos(a), s = sin(a); return mat3(c, s, 0.0, -s, c, 0.0, 0.0, 0.0, 1.0); }

float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}

// Rounded cylinder in revolution space: radius r, from y0 to y1, edge e.
float sdRCyl(vec2 q, float r, float y0, float y1, float e) {
  vec2 d = vec2(q.x - r + e, abs(q.y - 0.5 * (y0 + y1)) - 0.5 * (y1 - y0) + e);
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - e;
}

// The bottle as a solid (outer surface).
float sdBottle(vec3 p) {
  vec2 q = vec2(length(p.xz), p.y);
  float body = sdRCyl(q, RB, 0.0, BODY_TOP, 0.07);
  float neck = sdRCyl(q, 0.12, 0.9, 1.78, 0.03);
  float b = smin(body, neck, 0.32);
  float lip = length(vec2(q.x - 0.125, q.y - 1.76)) - 0.035;
  return min(b, lip);
}

float sdShell(vec3 p) { return abs(sdBottle(p)) - T; }

float sdLiquid(vec3 p) {
  vec2 q = vec2(length(p.xz), p.y);
  float inner = sdRCyl(q, RB - T * 2.2, T * 2.2, BODY_TOP, 0.05);
  float level = mix(0.08, BODY_TOP - 0.06, clamp(uLevel, 0.0, 1.0));
  float w = uWave * sin(9.0 * p.x + uTime * 3.4) * sin(8.0 * p.z - uTime * 2.7);
  float plane = dot(p - vec3(0.0, level, 0.0), gLiqN) - w;
  return max(inner, plane);
}

vec3 nLiquid(vec3 p) {
  const vec2 e = vec2(0.002, 0.0);
  return normalize(vec3(
      sdLiquid(p + e.xyy) - sdLiquid(p - e.xyy),
      sdLiquid(p + e.yxy) - sdLiquid(p - e.yxy),
      sdLiquid(p + e.yyx) - sdLiquid(p - e.yyx)));
}

vec3 nShell(vec3 p) {
  const vec2 e = vec2(0.002, 0.0);
  return normalize(vec3(
      sdShell(p + e.xyy) - sdShell(p - e.xyy),
      sdShell(p + e.yxy) - sdShell(p - e.yxy),
      sdShell(p + e.yyx) - sdShell(p - e.yyx)));
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = (frag - 0.5 * uSize) / uSize.y;
  uv.y = -uv.y;

  mat3 inv = rotX(-uRot.x) * rotZ(-uRot.z) * rotY(-uRot.y);
  vec3 ro = vec3(0.0, 0.0, 6.0);
  vec3 rd = normalize(vec3(uv, -2.55));
  vec3 rol = inv * ro + CENTER;
  vec3 rdl = inv * rd;
  gLiqN = inv * normalize(vec3(uSlosh.x, 1.0, uSlosh.y));
  vec3 light = inv * normalize(vec3(-0.5, 0.8, 0.6));
  float pix = 1.6 / uSize.y;

  // Liquid (opaque).
  float t = 0.0, edge = 1e9;
  bool hit = false;
  for (int i = 0; i < 80; i++) {
    float h = sdLiquid(rol + rdl * t);
    if (h < 0.0015) { hit = true; break; }
    edge = min(edge, h / (pix * t + 1e-4));
    t += h * 0.85;
    if (t > 12.0) break;
  }
  vec3 col = uBg;
  if (hit) {
    vec3 n = nLiquid(rol + rdl * t);
    float shade = 0.86 + 0.14 * max(dot(n, light), 0.0);
    shade *= 0.97 + 0.06 * max(dot(n, gLiqN), 0.0);
    col = uLiquid * shade;
  } else {
    col = mix(uLiquid, uBg, clamp(edge, 0.0, 1.0));
    t = 12.0;
  }

  // Glass: front and back walls, mostly edges (fresnel).
  float ts = 0.0;
  for (int layer = 0; layer < 2; layer++) {
    float found = -1.0;
    for (int i = 0; i < 72; i++) {
      float h = sdShell(rol + rdl * ts);
      if (h < 0.001) { found = ts; break; }
      ts += h * 0.9;
      if (ts > t) break;
    }
    if (found < 0.0 || found > t) break;
    vec3 n = nShell(rol + rdl * found);
    float fres = pow(1.0 - abs(dot(n, -rdl)), 2.0);
    float a = (layer == 0 ? 0.05 : 0.04) + 0.55 * fres;
    col = mix(col, uGlass, a);
    ts = found + 0.06;
  }

  fragColor = vec4(col, 1.0);
}
