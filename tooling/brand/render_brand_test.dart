// Renders assets/branding/*.svg to PNGs (icons at every size + previews).
//   python3 tooling/brand/make_svgs.py && flutter test tooling/brand/render_brand_test.dart
// Outputs to build/brand/. tooling/brand/install_icons.sh installs them.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> renderSvg(String svgPath, int size, String outPath) async {
  final info = await vg.loadPicture(SvgStringLoader(File(svgPath).readAsStringSync()), null);
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec);
  final s = size / info.size.width;
  canvas.scale(s, s);
  canvas.drawPicture(info.picture);
  final img = await rec.endRecording().toImage(size, size);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(outPath)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  info.picture.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render brand assets', () async {
    const src = 'assets/branding';
    const out = 'build/brand';
    for (final s in [64, 128, 256, 512, 1024]) {
      await renderSvg('$src/caskly_icon_mac.svg', s, '$out/mac_$s.png');
    }
    for (final s in [16, 32]) {
      await renderSvg('$src/caskly_icon_small.svg', s, '$out/mac_$s.png');
    }
    for (final s in [48, 64, 128, 256]) {
      await renderSvg('$src/caskly_icon_win.svg', s, '$out/win_$s.png');
    }
    for (final s in [16, 24, 32]) {
      await renderSvg('$src/caskly_icon_small.svg', s, '$out/win_$s.png');
    }
    await renderSvg('$src/caskly_mark.svg', 512, '$out/mark_512.png');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
