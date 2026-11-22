import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'figure.dart';

/// One fact on a card: gold icon dot, label, big figure, optional trailing
/// detail (delta, ●●○, "3 suppliers") and an ↗ button when tappable.
class FactCard extends StatelessWidget {
  const FactCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
    this.onTap,
    this.prefix,
    this.unit,
    this.iconFill,
    this.badge,
    this.figureSize = 34,
    this.valueColor,
    this.surface,
    this.caption,
  });

  final AppIconData icon;
  final String title;
  final String value;
  final String? prefix;
  final String? unit;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconFill;

  /// Replaces the ↗ button top-right (e.g. a "SOON" tag).
  final Widget? badge;
  final double figureSize;
  final Color? valueColor;

  /// Card fill; defaults to white (ink in dark mode).
  final Color? surface;

  /// Shown instead of the figure when [value] is empty.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark(context);
    return Material(
      color: surface ?? (dark ? AppColors.ink : Colors.white),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: iconFill ?? AppColors.primary),
                    child: AppIcon(icon, size: 15, color: AppColors.ink),
                  ),
                  const Spacer(),
                  if (badge != null) badge!,
                  if (onTap != null && badge == null)
                    CircleIconButton(
                      size: 28,
                      onTap: onTap,
                      tooltip: 'Open',
                      child: AppIcon(AppIcons.northEast, size: 13, color: AppColors.textPrimaryFor(context)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textPrimaryFor(context), fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (value.isEmpty && caption != null)
                    Expanded(
                      child: Text(caption!,
                          style: AppTypography.bodyMuted.copyWith(color: AppColors.textSecondaryFor(context))),
                    )
                  else
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          child: Figure(value, prefix: prefix, unit: unit, size: figureSize, color: valueColor),
                        ),
                      ),
                    ),
                  if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
