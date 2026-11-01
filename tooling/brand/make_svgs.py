#!/usr/bin/env python3
"""Generates the Caskly brand SVG masters (assets/branding/).

The mark: the classic cocktail glass the app has always used, refined —
ink-black glass with real thickness, brand-purple liquid with a meniscus,
a green olive with pimento on a pick, all on a soft white tile.

Variants (1024 viewBox):
  caskly_icon_mac.svg    macOS grid: tile inset with margin + soft shadow
  caskly_icon_win.svg    Windows: near full-bleed tile (taskbar/Explorer)
  caskly_icon_small.svg  16–32 px: simplified glass, no olive/highlights
  caskly_mark.svg        glass only, transparent (in-app logo on own tile)
No SVG filters are used (flutter_svg can't render them); shadows are layered shapes.
"""
import os

OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'branding')

DEFS = """
  <linearGradient id="tile" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#FFFFFF"/>
    <stop offset="0.55" stop-color="#F7F6FB"/>
    <stop offset="1" stop-color="#ECEAF3"/>
  </linearGradient>
  <linearGradient id="tileEdge" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#FFFFFF"/>
    <stop offset="1" stop-color="#D9D6E4"/>
  </linearGradient>
  <linearGradient id="ink" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#2B2B36"/>
    <stop offset="0.45" stop-color="#16161F"/>
    <stop offset="1" stop-color="#0B0B10"/>
  </linearGradient>
  <linearGradient id="inkV" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#2E2E3A"/>
    <stop offset="1" stop-color="#101016"/>
  </linearGradient>
  <linearGradient id="glassIn" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#FFFFFF"/>
    <stop offset="1" stop-color="#E4E2EE"/>
  </linearGradient>
  <linearGradient id="liquid" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#8E80F2"/>
    <stop offset="0.5" stop-color="#6C5CE7"/>
    <stop offset="1" stop-color="#3B2CA8"/>
  </linearGradient>
  <linearGradient id="liquidSheen" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.38"/>
    <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
  </linearGradient>
  <radialGradient id="olive" cx="0.38" cy="0.32" r="0.75">
    <stop offset="0" stop-color="#C7DB7A"/>
    <stop offset="0.45" stop-color="#7E9B33"/>
    <stop offset="1" stop-color="#3F5512"/>
  </radialGradient>
  <radialGradient id="pimento" cx="0.4" cy="0.35" r="0.7">
    <stop offset="0" stop-color="#F06A55"/>
    <stop offset="1" stop-color="#A3261A"/>
  </radialGradient>
  <radialGradient id="pickHead" cx="0.35" cy="0.3" r="0.7">
    <stop offset="0" stop-color="#C0574F"/>
    <stop offset="1" stop-color="#6E211B"/>
  </radialGradient>
  <radialGradient id="contact" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="#1A1830" stop-opacity="0.28"/>
    <stop offset="1" stop-color="#1A1830" stop-opacity="0"/>
  </radialGradient>
"""


def glass(detail=True):
    """The glass, drawn in a 1024 box, centred on x=512."""
    g = []
    # Contact shadow under the foot.
    g.append('<ellipse cx="512" cy="800" rx="190" ry="26" fill="url(#contact)"/>')
    # Bowl (outer, ink) — slightly curved walls, rounded apex.
    g.append('<path d="M 268 300 Q 260 300 266 309 L 486 586 Q 512 614 538 586 L 758 309 '
             'Q 764 300 756 300 Z" fill="url(#ink)"/>')
    if detail:
        # Glass interior (the clear part above the drink).
        g.append('<path d="M 322 330 L 702 330 L 512 566 Z" fill="url(#glassIn)"/>')
        # Liquid: fills the lower bowl.
        g.append('<path d="M 368 388 L 656 388 L 512 566 Z" fill="url(#liquid)"/>')
        # Meniscus line + soft sheen on the liquid.
        g.append('<path d="M 368 388 L 656 388" stroke="#B3A8F8" stroke-width="7" stroke-linecap="round"/>')
        g.append('<path d="M 392 404 L 490 526" stroke="url(#liquidSheen)" stroke-width="16" stroke-linecap="round"/>')
        # Rim highlight on the ink.
        g.append('<path d="M 282 309 L 742 309" stroke="#5A5A6A" stroke-width="5" stroke-linecap="round" opacity="0.55"/>')
        # Pick through the olive, resting on the rim.
        g.append('<path d="M 664 214 L 500 476" stroke="#9A98A8" stroke-width="9" stroke-linecap="round"/>')
        g.append('<path d="M 664 214 L 500 476" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" opacity="0.45"/>')
        g.append('<circle cx="668" cy="208" r="17" fill="url(#pickHead)"/>')
        # Olive (sits in the drink) with its pimento.
        g.append('<ellipse cx="548" cy="440" rx="46" ry="38" transform="rotate(-32 548 440)" fill="url(#olive)"/>')
        g.append('<ellipse cx="530" cy="424" rx="13" ry="10" transform="rotate(-32 530 424)" fill="url(#pimento)"/>')
        g.append('<ellipse cx="562" cy="428" rx="12" ry="6" transform="rotate(-32 562 428)" fill="#FFFFFF" opacity="0.35"/>')
    else:
        # Small sizes: bold silhouette — one big liquid area, nothing fiddly.
        g.append('<path d="M 318 336 L 706 336 L 512 572 Z" fill="url(#liquid)"/>')
    # Stem and foot.
    stem_w = 28 if detail else 64
    g.append(f'<rect x="{512 - stem_w / 2}" y="580" width="{stem_w}" height="190" rx="{stem_w / 2}" fill="url(#ink)"/>')
    foot_w, foot_h = (250, 32) if detail else (330, 70)
    g.append(f'<rect x="{512 - foot_w / 2}" y="{776 - foot_h / 2}" width="{foot_w}" height="{foot_h}" rx="{foot_h / 2}" fill="url(#inkV)"/>')
    if detail:
        g.append('<path d="M 410 766 L 614 766" stroke="#6A6A7A" stroke-width="4" stroke-linecap="round" opacity="0.6"/>')
    return '\n  '.join(g)


def tile(x, r, shadow=True):
    w = 1024 - 2 * x
    parts = []
    if shadow:
        # Layered soft shadow (no SVG filters).
        # Many faint layers read as one smooth shadow (few layers looked stepped).
        for i, (dy, grow, op) in enumerate([(2 + k * 3, k * 2, 0.018) for k in range(10)]):
            parts.append(f'<rect x="{x - grow}" y="{x - grow + dy}" width="{w + 2 * grow}" height="{w + 2 * grow}" '
                         f'rx="{r + grow}" fill="#1A1830" opacity="{op}"/>')
    parts.append(f'<rect x="{x}" y="{x}" width="{w}" height="{w}" rx="{r}" fill="url(#tileEdge)"/>')
    parts.append(f'<rect x="{x + 3}" y="{x + 3}" width="{w - 6}" height="{w - 6}" rx="{r - 3}" fill="url(#tile)"/>')
    return '\n  '.join(parts)


def svg(body, scale=1.0, cx=512, cy=512):
    # Optional glyph scale about the centre (so the glass fills each tile well).
    group = body if scale == 1.0 else (
        f'<g transform="translate({cx} {cy}) scale({scale}) translate({-cx} {-cy})">\n  {body}\n  </g>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">\n<defs>{DEFS}</defs>\n  {group}\n</svg>\n'


def main():
    os.makedirs(OUT, exist_ok=True)
    files = {
        'caskly_icon_mac.svg': svg(tile(100, 185) + '\n  ' + f'<g transform="translate(512 512) scale(1.0) translate(-512 -505)">{glass(True)}</g>'),
        'caskly_icon_win.svg': svg(tile(28, 200, shadow=False) + '\n  ' + f'<g transform="translate(512 512) scale(1.12) translate(-512 -505)">{glass(True)}</g>'),
        'caskly_icon_small.svg': svg(tile(16, 190, shadow=False) + '\n  ' + f'<g transform="translate(512 520) scale(1.38) translate(-512 -540)">{glass(False)}</g>'),
        'caskly_mark.svg': svg(f'<g transform="translate(512 520) scale(1.18) translate(-512 -520)">{glass(True)}</g>'),
    }
    for name, content in files.items():
        with open(os.path.join(OUT, name), 'w') as f:
            f.write(content)
        print('wrote', name)


if __name__ == '__main__':
    main()
