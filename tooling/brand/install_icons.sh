#!/bin/zsh
# Regenerates and installs the Caskly app icons from the SVG masters.
#   tooling/brand/install_icons.sh
set -e
cd "$(dirname "$0")/../.."
python3 tooling/brand/make_svgs.py
flutter test tooling/brand/render_brand_test.dart >/dev/null
B=build/brand
MAC=macos/Runner/Assets.xcassets/AppIcon.appiconset
for s in 16 32 64 128 256 512 1024; do cp "$B/mac_$s.png" "$MAC/app_icon_$s.png"; done
cp "$B/mac_1024.png" assets/branding/caskly_app_icon_master.png
# Windows .ico with embedded PNGs (Vista+ format), 16–256 px.
python3 - "$B" windows/runner/resources/app_icon.ico <<'PY'
import struct, sys, os
src, out = sys.argv[1], sys.argv[2]
sizes = [16, 24, 32, 48, 64, 128, 256]
blobs = [open(os.path.join(src, f"win_{s}.png"), "rb").read() for s in sizes]
entries, offset = b"", 6 + 16 * len(sizes)
for s, b in zip(sizes, blobs):
    d = 0 if s == 256 else s
    entries += struct.pack("<BBBBHHII", d, d, 0, 0, 1, 32, len(b), offset)
    offset += len(b)
open(out, "wb").write(struct.pack("<HHH", 0, 1, len(sizes)) + entries + b"".join(blobs))
print("wrote", out)
PY
echo "Icons installed (macOS, Windows, installer)."
