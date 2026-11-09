#!/usr/bin/env python3
"""Generates the Caskly brand SVG masters (assets/branding/).

The mark: a flat, solid martini glass in cream on a matte ink tile. The
drink is drawn by a single cut of negative space across the bowl, which
splits a thin rim from the drink. Two colours, no gradients or gloss —
deliberately restrained (glossy/illustrated versions were rejected).

Variants (1024 viewBox):
  caskly_icon_mac.svg    macOS grid: tile inset with margin + soft shadow
  caskly_icon_win.svg    Windows: near full-bleed tile (taskbar/Explorer)
  caskly_icon_small.svg  16–48 px: same glass, heavier stem/foot/cut
  caskly_mark.svg        glass only in ink, transparent (for light grounds)
  caskly_mark_light.svg  glass only in cream, transparent (for dark grounds)
No SVG filters are used (flutter_svg can't render them); the shadow is layered shapes.
"""
import os

OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'branding')

INK = '#141218'
CREAM = '#F3EFE6'

# Bowl geometry (1024 box): rim from x=292..732 at y=296, apex at (512, 552).
RIM_Y, RIM_L, RIM_R, APEX = 296, 292, 732, 552


def _x_at(y, side):
    """x on the bowl wall at height y (side -1 = left, +1 = right)."""
    t = (y - RIM_Y) / (APEX - RIM_Y)
    return RIM_L + (512 - RIM_L) * t if side < 0 else RIM_R - (RIM_R - 512) * t


def glass(fg, bold=False):
    """The martini in one colour; the cut is transparent (true negative space)."""
    cut_y = 344 if not bold else 352
    cut = 14 if not bold else 30
    sw = 22 if not bold else 46
    soft = 16  # corner rounding via a same-colour stroke
    top, bot = cut_y - cut / 2, cut_y + cut / 2
    rim = f'M {RIM_L} {RIM_Y} L {RIM_R} {RIM_Y} L {_x_at(top - soft / 2, 1):.1f} {top - soft / 2} L {_x_at(top - soft / 2, -1):.1f} {top - soft / 2} Z'
    drink = f'M {_x_at(bot + soft / 2, -1):.1f} {bot + soft / 2} L {_x_at(bot + soft / 2, 1):.1f} {bot + soft / 2} L 512 {APEX} Z'
    g = [
        # Stem (with a short flare into the bowl) and foot, behind the bowl.
        # Flare starts on the bowl walls (hidden under the drink) so the
        # join has no slivers.
        f'<path d="M {_x_at(APEX - 34, -1):.1f} {APEX - 34} Q {512 - sw / 2} {APEX} {512 - sw / 2} {APEX + 34} '
        f'L {512 + sw / 2} {APEX + 34} Q {512 + sw / 2} {APEX} {_x_at(APEX - 34, 1):.1f} {APEX - 34} Z" fill="{fg}"/>',
        f'<rect x="{512 - sw / 2}" y="{APEX - 4}" width="{sw}" height="{758 - APEX}" fill="{fg}"/>',
        f'<rect x="{512 - 128}" y="752" width="256" height="{sw}" rx="{sw / 2}" fill="{fg}"/>',
        f'<path d="{rim}" fill="{fg}" stroke="{fg}" stroke-width="{soft}" stroke-linejoin="round"/>',
        f'<path d="{drink}" fill="{fg}" stroke="{fg}" stroke-width="{soft}" stroke-linejoin="round"/>',
    ]
    return ''.join(g)


def tile(x, r, shadow=True):
    w = 1024 - 2 * x
    parts = []
    if shadow:
        # Many faint layers read as one smooth shadow (few layers looked stepped).
        for k in range(10):
            parts.append(f'<rect x="{x - k * 2}" y="{x - k * 2 + 2 + k * 3}" width="{w + 4 * k}" height="{w + 4 * k}" '
                         f'rx="{r + k * 2}" fill="#0A0910" opacity="0.022"/>')
    parts.append(f'<rect x="{x}" y="{x}" width="{w}" height="{w}" rx="{r}" fill="{INK}"/>')
    return '\n  '.join(parts)


def placed(body, scale, cy=512):
    return f'<g transform="translate(512 {cy}) scale({scale}) translate(-512 -524)">{body}</g>'


def svg(body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">\n'
            f'  {body}\n</svg>\n')


def main():
    os.makedirs(OUT, exist_ok=True)
    files = {
        'caskly_icon_mac.svg': svg(tile(100, 185) + '\n  ' + placed(glass(CREAM), 1.0)),
        'caskly_icon_win.svg': svg(tile(28, 200, shadow=False) + '\n  ' + placed(glass(CREAM), 1.14)),
        'caskly_icon_small.svg': svg(tile(16, 190, shadow=False) + '\n  ' + placed(glass(CREAM, bold=True), 1.28)),
        'caskly_mark.svg': svg(placed(glass(INK), 1.5)),
        'caskly_mark_light.svg': svg(placed(glass(CREAM), 1.5)),
    }
    for name, content in files.items():
        with open(os.path.join(OUT, name), 'w') as f:
            f.write(content)
        print('wrote', name)


if __name__ == '__main__':
    main()
