import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class VerticalBarData {
  const VerticalBarData({required this.label, required this.valueLabel, required this.fraction, this.color});
  final String label;
  final String valueLabel;
  final double fraction; // 0..1, height relative to the tallest bar
  final Color? color;
}

/// Simple vertical bar chart — value label on top, bar, category label
/// underneath. Used for "Sales — last 7 days".
class VerticalBarChart extends StatelessWidget {
  const VerticalBarChart({super.key, required this.data, this.height = 220});

  final List<VerticalBarData> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxBarHeight = height - 46;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bar in data)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(bar.valueLabel, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      height: (maxBarHeight * bar.fraction).clamp(4, maxBarHeight),
                      decoration: BoxDecoration(
                        color: bar.color ?? AppColors.primary,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(bar.label, style: AppTypography.caption),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
