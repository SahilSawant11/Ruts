import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.compact = false,
    this.showWordmark = true,
  });

  final bool compact;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.borderFor(context);
    final subtitleColor = AppColors.textSecondaryFor(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactMark = constraints.maxWidth.isFinite
            ? (constraints.maxWidth.clamp(20.0, 32.0)).toDouble()
            : 32.0;
        final markSize = compact ? compactMark : 38.0;
        final iconSize = compact ? (markSize * 0.56).clamp(12.0, 18.0) : 20.0;

        final mark = Container(
          width: markSize,
          height: markSize,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: borderColor),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.local_bar_rounded,
            size: iconSize,
            color: AppColors.primary,
          ),
        );

        if (!showWordmark) {
          final fittedWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : markSize;
          return SizedBox(
            width: fittedWidth,
            height: markSize,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              child: mark,
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            const SizedBox(width: AppSpacing.sm),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Caskly',
                  style: AppTypography.sectionTitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Liquor POS',
                  style: AppTypography.caption.copyWith(
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
