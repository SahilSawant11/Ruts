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
uniform float uShape;   // 0 whisky, 1 wine, 2 beer, 3 rum, 4 vodka, 5 gin, 6 brandy, 7 can, 8 generic

out vec4 fragColor;

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

// Rounded box, centred at c, half-size b, corner radius e.
float sdRBox(vec3 p, vec3 c, vec3 b, float e) {
  vec3 d = abs(p - c) - b + e;
  return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0) - e;
}

// Neck + lip shared by most bottles.
float neckLip(vec2 q, float r, float y0, float y1) {
  float neck = sdRCyl(q, r, y0, y1, 0.03);
  float lip = length(vec2(q.x - r - 0.005, q.y - y1 + 0.02)) - 0.03;
  return min(neck, lip);
}

// The bottle as a solid (outer surface), by category shape.
float sdBottle(vec3 p) {
  vec2 q = vec2(length(p.xz), p.y);
  if (uShape < 0.5) {         // whisky: square decanter, short neck, stopper
    float body = sdRBox(p, vec3(0.0, 0.44, 0.0), vec3(0.40, 0.44, 0.40), 0.08);
    float b = smin(body, sdRCyl(q, 0.13, 0.7, 1.24, 0.03), 0.12);
    return min(b, sdRCyl(q, 0.17, 1.2, 1.4, 0.05));
  } else if (uShape < 1.5) {  // wine: Bordeaux, high shoulders, long neck
    return smin(sdRCyl(q, 0.32, 0.0, 1.06, 0.05), neckLip(q, 0.105, 0.95, 1.86), 0.13);
  } else if (uShape < 2.5) {  // beer: longneck, long sloping shoulder
    return smin(sdRCyl(q, 0.30, 0.0, 0.86, 0.05), neckLip(q, 0.095, 0.7, 1.8), 0.5);
  } else if (uShape < 3.5) {  // rum: short round-shouldered flask
    return smin(sdRCyl(q, 0.42, 0.0, 0.78, 0.1), neckLip(q, 0.12, 0.6, 1.5), 0.42);
  } else if (uShape < 4.5) {  // vodka: tall slim column
    return smin(sdRCyl(q, 0.28, 0.0, 1.34, 0.05), neckLip(q, 0.12, 1.25, 1.78), 0.1);
  } else if (uShape < 5.5) {  // gin: tall square bottle
    float body = sdRBox(p, vec3(0.0, 0.58, 0.0), vec3(0.33, 0.58, 0.33), 0.05);
    return smin(body, neckLip(q, 0.12, 1.05, 1.62), 0.1);
  } else if (uShape < 6.5) {  // brandy: round cognac body
    float body = (length((p - vec3(0.0, 0.36, 0.0)) * vec3(1.0, 1.45, 1.0)) - 0.5) / 1.45;
    return smin(body, neckLip(q, 0.1, 0.55, 1.25), 0.2);
  } else if (uShape < 7.5) {  // can
    float body = sdRCyl(q, 0.33, 0.0, 1.16, 0.06);
    float top = sdRCyl(q, 0.28, 1.08, 1.26, 0.04);
    return smin(body, top, 0.05);
  }
  // generic
  return smin(sdRCyl(q, 0.40, 0.0, 1.02, 0.07), neckLip(q, 0.12, 0.9, 1.76), 0.32);
}

// Height the liquid can reach (top of the body, below the shoulder).
float bodyTop() {
  if (uShape < 0.5) return 0.8;
  if (uShape < 1.5) return 1.0;
  if (uShape < 2.5) return 0.78;
  if (uShape < 3.5) return 0.72;
  if (uShape < 4.5) return 1.28;
  if (uShape < 5.5) return 1.08;
  if (uShape < 6.5) return 0.6;
  if (uShape < 7.5) return 1.08;
  return 0.96;
}

float sdShell(vec3 p) { return abs(sdBottle(p)) - T; }

float sdLiquid(vec3 p) {
  float inner = sdBottle(p) + T * 2.2;
  float level = mix(0.08, bodyTop(), clamp(uLevel, 0.0, 1.0));
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
  float pix = 1.0 / (uSize.y * 2.55); // world size of one pixel per unit distance

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
