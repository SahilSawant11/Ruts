import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

class DonutSegment {
  const DonutSegment({required this.value, required this.color});
  final double value;
  final Color color;
}

/// Ring chart with a value + caption centered inside. Segment sizes
/// are proportional to `value`. Used for "Stock Health".
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    required this.centerValue,
    required this.centerLabel,
    this.size = 132,
    this.strokeWidth = 16,
  });

  final List<DonutSegment> segments;
  final String centerValue;
  final String centerLabel;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(segments: segments, strokeWidth: strokeWidth),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerValue, style: AppTypography.h1.copyWith(fontSize: 22)),
              Text(centerLabel, style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments, required this.strokeWidth});

  final List<DonutSegment> segments;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (a, b) => a + b.value);
    if (total <= 0) return;

    final rect = Offset.zero & size;
    final inflatedRect = rect.deflate(strokeWidth / 2);
    var startAngle = -1.5708; // -90deg, start at top

    for (final segment in segments) {
      final sweep = (segment.value / total) * 6.28319;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(inflatedRect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.segments != segments;
}
