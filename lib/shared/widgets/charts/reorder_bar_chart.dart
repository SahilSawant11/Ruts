import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class ReorderBarData {
  const ReorderBarData({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;
}

/// Vertical bars scaled against the tallest value in the set, with a
/// dashed "Reorder level" threshold line overlaid. Bar color already
/// encodes status (green/amber/red) per the source data.
class ReorderBarChart extends StatelessWidget {
  const ReorderBarChart({super.key, required this.data, this.height = 240, this.thresholdFraction = 0.32});

  final List<ReorderBarData> data;
  final double height;

  /// Where the dashed reorder-level line sits, as a fraction of chart
  /// height measured from the bottom.
  final double thresholdFraction;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.map((d) => d.value).fold<int>(1, (a, b) => a > b ? a : b);
    final barAreaHeight = height - 24;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 24 + (barAreaHeight * thresholdFraction),
            child: Row(
              children: [
                Expanded(child: _DashedLine(color: AppColors.warning)),
                const SizedBox(width: 6),
                Text(
                  'Reorder level',
                  style: AppTypography.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final bar in data)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('${bar.value}', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Container(
                          height: (barAreaHeight * (bar.value / maxValue)).clamp(3, barAreaHeight),
                          decoration: BoxDecoration(
                            color: bar.color,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          bar.label,
                          style: AppTypography.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 2),
      painter: _DashedLinePainter(color),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
