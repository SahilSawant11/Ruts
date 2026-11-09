// The Caskly martini in 3D, for the login screen.
//
// Matte and two-colour like the mark: a solid cream rim, a faint glass
// bowl, a solid cream drink, stem and foot, on flat ink. Raymarched signed
// distance fields; the glass is a surface of revolution around local y.
//
// Local frame: bowl apex at the origin, rim at y = H. The Dart side drives
// rotation (tilt with the mouse), the drink's surface tilt (slosh) and a
// ripple amplitude (swirl); this shader only draws.
#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;    // canvas size in pixels
uniform float uTime;   // seconds
uniform vec3 uRot;     // pitch (x), yaw (y), roll (z), radians
uniform vec2 uSlosh;   // drink surface tilt in world space (x, z)
uniform float uWave;   // ripple amplitude
uniform vec3 uBg;      // background (ink)
uniform vec3 uFg;      // glass + drink (cream)

out vec4 fragColor;

const float H = 1.0;      // bowl height
const float R = 1.08;     // rim radius
const float T = 0.016;    // bowl wall half-thickness
const float LIQ = 0.68;   // drink level in the bowl
const vec3 CENTER = vec3(0.0, -0.14, 0.0); // rotate about the glass's middle

vec3 gLiqN = vec3(0.0, 1.0, 0.0); // drink surface normal, glass-local

mat3 rotX(float a) { float c = cos(a), s = sin(a); return mat3(1.0, 0.0, 0.0, 0.0, c, s, 0.0, -s, c); }
mat3 rotY(float a) { float c = cos(a), s = sin(a); return mat3(c, 0.0, -s, 0.0, 1.0, 0.0, s, 0.0, c); }
mat3 rotZ(float a) { float c = cos(a), s = sin(a); return mat3(c, s, 0.0, -s, c, 0.0, 0.0, 0.0, 1.0); }

float sdSeg(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p - a, ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h);
}

float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}

vec2 rev(vec3 p) { return vec2(length(p.xz), p.y); }

float sdShell(vec3 p) { return sdSeg(rev(p), vec2(0.0), vec2(R, H)) - T; }
float sdRim(vec3 p) { vec2 q = vec2(length(p.xz) - R, p.y - H); return length(q) - 0.03; }

float sdStemFoot(vec3 p) {
  vec2 q = rev(p);
  float stem = sdSeg(q, vec2(0.0, -1.26), vec2(0.0, 0.02)) - 0.038;
  float foot = sdSeg(q, vec2(0.0, -1.285), vec2(0.58, -1.30)) - 0.026;
  return smin(stem, foot, 0.05);
}

float sdDrink(vec3 p) {
  vec2 q = rev(p);
  float cone = dot(q, normalize(vec2(H, -R))) + T * 1.8;
  float w = uWave * sin(7.0 * p.x + uTime * 3.3) * sin(6.0 * p.z - uTime * 2.6);
  float plane = dot(p - vec3(0.0, LIQ, 0.0), gLiqN) - w;
  return max(cone, plane);
}

// x: distance, y: material (1 rim, 2 drink, 3 stem/foot)
vec2 mapSolid(vec3 p) {
  vec2 r = vec2(sdRim(p), 1.0);
  float d = sdDrink(p);
  if (d < r.x) r = vec2(d, 2.0);
  float s = sdStemFoot(p);
  if (s < r.x) r = vec2(s, 3.0);
  return r;
}

vec3 normalSolid(vec3 p) {
  const vec2 e = vec2(0.0015, 0.0);
  return normalize(vec3(
      mapSolid(p + e.xyy).x - mapSolid(p - e.xyy).x,
      mapSolid(p + e.yxy).x - mapSolid(p - e.yxy).x,
      mapSolid(p + e.yyx).x - mapSolid(p - e.yyx).x));
}

vec3 normalShell(vec3 p) {
  const vec2 e = vec2(0.0015, 0.0);
  return normalize(vec3(
      sdShell(p + e.xyy) - sdShell(p - e.xyy),
      sdShell(p + e.yxy) - sdShell(p - e.yxy),
      sdShell(p + e.yyx) - sdShell(p - e.yyx)));
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = (frag - 0.5 * uSize) / uSize.y;
  uv.y = -uv.y;

  // Inverse of rotY * rotZ * rotX, built from negative angles (SkSL, which
  // Windows' Skia renderer uses, has no transpose()).
  mat3 inv = rotX(-uRot.x) * rotZ(-uRot.z) * rotY(-uRot.y);

  vec3 ro = vec3(0.0, 0.0, 9.6);
  vec3 rd = normalize(vec3(uv, -1.65));
  vec3 rol = inv * ro + CENTER;
  vec3 rdl = inv * rd;
  gLiqN = inv * normalize(vec3(uSlosh.x, 1.0, uSlosh.y));
  vec3 light = inv * normalize(vec3(-0.55, 0.75, 0.65));

  float pix = 1.0 / uSize.y * 1.6; // one pixel's angular size, for edge AA

  // Solid parts.
  float t = 0.0, id = 0.0, edge = 1e9;
  for (int i = 0; i < 96; i++) {
    vec2 h = mapSolid(rol + rdl * t);
    if (h.x < 0.0012) { id = h.y; break; }
    edge = min(edge, h.x / (pix * t + 1e-4));
    t += h.x * 0.82;
    if (t > 16.0) break;
  }

  vec3 col = uBg;
  if (id > 0.0) {
    vec3 p = rol + rdl * t;
    vec3 n = normalSolid(p);
    float diff = max(dot(n, light), 0.0);
    float shade = 0.84 + 0.16 * diff; // nearly flat, like the mark
    if (id == 2.0) shade *= 0.95 + 0.07 * max(dot(n, gLiqN), 0.0); // drink top a touch brighter
    col = uFg * shade;
  } else {
    // Soft silhouette instead of stair-stepped edges.
    col = mix(uFg * 0.9, uBg, clamp(edge, 0.0, 1.0));
    t = 16.0;
  }

  // Glass bowl: two thin translucent layers (front and back wall).
  float ts = 0.0;
  for (int layer = 0; layer < 2; layer++) {
    float hit = -1.0;
    for (int i = 0; i < 64; i++) {
      float h = sdShell(rol + rdl * ts);
      if (h < 0.0008) { hit = ts; break; }
      ts += h * 0.9;
      if (ts > t) break;
    }
    if (hit < 0.0 || hit > t) break;
    vec3 n = normalShell(rol + rdl * hit);
    float fres = pow(1.0 - abs(dot(n, -rdl)), 2.2);
    float a = (layer == 0 ? 0.07 : 0.05) + 0.42 * fres;
    col = mix(col, uFg, a);
    ts = hit + 0.05;
  }

  fragColor = vec4(col, 1.0);
}
