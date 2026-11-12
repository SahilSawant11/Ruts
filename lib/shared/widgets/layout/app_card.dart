import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Card surfaces of the flat card system.
/// - [plain]: white (dark: surface) with a hairline border — the default.
/// - [ink]: near-black brand ink, cream text — for charts and emphasis.
/// - [cream]: warm off-white — secondary groups on a plain canvas.
/// - [gold]: the toned-down brand field (pale wheat / warm brown).
enum CardTone { plain, ink, cream, gold }

/// Rounded, flat container. Every panel in the app sits inside one.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.tone = CardTone.plain,
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsets padding;
  final CardTone tone;
  final double radius;

  static Color fillFor(BuildContext context, CardTone tone) => switch (tone) {
        CardTone.plain => AppColors.backgroundFor(context),
        CardTone.ink => AppColors.isDark(context) ? AppColors.inkSoft : AppColors.ink,
        CardTone.cream => AppColors.creamFor(context),
        CardTone.gold => AppColors.goldFieldFor(context),
      };

  /// Main text colour on a [tone] surface.
  static Color onColorFor(BuildContext context, CardTone tone) => switch (tone) {
        CardTone.plain || CardTone.cream => AppColors.textPrimaryFor(context),
        CardTone.ink => AppColors.cream,
        CardTone.gold => AppColors.isDark(context) ? AppColors.cream : AppColors.ink,
      };

  /// Secondary text colour on a [tone] surface.
  static Color mutedOnFor(BuildContext context, CardTone tone) => switch (tone) {
        CardTone.plain || CardTone.cream => AppColors.textSecondaryFor(context),
        CardTone.ink => AppColors.cream.withValues(alpha: 0.6),
        CardTone.gold => (AppColors.isDark(context) ? AppColors.cream : AppColors.ink).withValues(alpha: 0.62),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fillFor(context, tone),
        borderRadius: BorderRadius.circular(radius),
        border: tone == CardTone.plain ? Border.all(color: AppColors.borderFor(context)) : null,
      ),
      child: child,
    );
  }
}

/// Bold title + muted subtitle used at the top of every AppCard,
/// with an optional trailing widget (a chip, a button, ...).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final AppIconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          AppIcon(icon!, size: 17, color: AppColors.primary),
          const SizedBox(width: 8),
        ],
        // The title always wins; the subtitle shows only if at least ~110px
        // remain after it (otherwise both got ellipsised on narrow screens).
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final titleStyle = AppTypography.sectionTitle.copyWith(color: AppColors.textPrimaryFor(context));
            final painter = TextPainter(
              text: TextSpan(text: title, style: titleStyle),
              maxLines: 1,
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout();
            final showSubtitle =
                subtitle != null && constraints.maxWidth - painter.width - AppSpacing.xs >= 110;
            return Row(
              children: [
                Flexible(
                  child: Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (showSubtitle) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: AppTypography.bodyMuted.copyWith(color: AppColors.textSecondaryFor(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            );
          }),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.xs),
          // Natural width, pinned right (a Flexible here took half the row
          // and pushed buttons/chips into the middle of the card).
          trailing!,
        ],
      ],
    );
  }
}
