#!/usr/bin/env python3
"""Generates the Caskly wordmark (assets/branding/caskly_wordmark*.svg).

Stacked lockup: the martini mark above "CASKLY" in Manrope Medium with
wide tracking. Letters are outlined to SVG paths from the bundled font,
so the files look identical everywhere (no font needed to view them).

Needs fontTools:  python3 -m pip install fonttools
  python3 tooling/brand/make_wordmark.py
"""
import os
import sys

from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True
import make_svgs as M  # noqa: E402  (shares the mark geometry + colours)

ROOT = os.path.join(HERE, '..', '..')
OUT = os.path.join(ROOT, 'assets', 'branding')
FONT = os.path.join(ROOT, 'assets', 'fonts', 'Manrope-Medium.ttf')

TEXT = 'CASKLY'
TRACKING_EM = 0.32   # letter spacing, as a fraction of the em
MARK_H = 260         # mark height (rim top to foot)
CAP_H = 70           # cap height of the letters
GAP = 70             # mark foot to cap top
PAD = 40             # clear space around the lockup

# Mark bbox inside its own 1024 box (rim top .. foot bottom).
MX0, MY0, MX1, MY1 = 292, 288, 732, 774


def outline(text):
    font = TTFont(FONT)
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    advance = font['hmtx']
    upem = font['head'].unitsPerEm
    x, parts = 0, []
    for i, ch in enumerate(text):
        name = cmap[ord(ch)]
        pen = SVGPathPen(glyphs)
        glyphs[name].draw(pen)
        parts.append(f'<path transform="translate({x} 0)" d="{pen.getCommands()}"/>')
        x += advance[name][0] + (TRACKING_EM * upem if i < len(text) - 1 else 0)
    return ''.join(parts), x, font['OS/2'].sCapHeight


def lockup(fg):
    paths, adv, cap = outline(TEXT)
    s = CAP_H / cap
    word_w = adv * s
    mark_w = MARK_H * (MX1 - MX0) / (MY1 - MY0)
    w = max(word_w, mark_w) + PAD * 2
    ms = MARK_H / (MY1 - MY0)
    mark = (f'<g transform="translate({(w - mark_w) / 2:.2f} {PAD}) scale({ms:.5f}) translate({-MX0} {-MY0})">'
            f'{M.glass(fg)}</g>')
    baseline = PAD + MARK_H + GAP + CAP_H
    word = f'<g fill="{fg}" transform="translate({(w - word_w) / 2:.2f} {baseline}) scale({s:.5f} {-s:.5f})">{paths}</g>'
    h = baseline + PAD
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w:.0f}" height="{h:.0f}" viewBox="0 0 {w:.2f} {h:.2f}">'
            f'\n  {mark}\n  {word}\n</svg>\n')


def main():
    for name, fg in (('caskly_wordmark.svg', M.INK), ('caskly_wordmark_light.svg', M.CREAM)):
        with open(os.path.join(OUT, name), 'w') as f:
            f.write(lockup(fg))
        print('wrote', name)


if __name__ == '__main__':
    main()
