import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// A big display number with a small unit, the card system's hero element:
/// `₹1,19,450`, `17 bills`, `14 %`.
///
/// [prefix] sits small and raised before the number (currency); [unit]
/// sits small after it, aligned to the top like a superscript.
class Figure extends StatelessWidget {
  const Figure(
    this.value, {
    super.key,
    this.prefix,
    this.unit,
    this.size = 40,
    this.color,
    this.weight = FontWeight.w300,
  });

  final String value;
  final String? prefix;
  final String? unit;
  final double size;
  final Color? color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimaryFor(context);
    final small = AppTypography.figure(size: (size * 0.36).clamp(11, 22), weight: FontWeight.w500, color: c);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (prefix != null)
          Padding(
            padding: EdgeInsets.only(top: size * 0.08, right: size * 0.06),
            child: Text(prefix!, style: small),
          ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: AppTypography.figure(size: size, weight: weight, color: c),
          ),
        ),
        if (unit != null)
          Padding(
            padding: EdgeInsets.only(top: size * 0.08, left: size * 0.08),
            child: Text(unit!, style: small),
          ),
      ],
    );
  }
}

/// ●●○ — a 0–[of] level, e.g. how urgent a low-stock count is.
class LevelDots extends StatelessWidget {
  const LevelDots({super.key, required this.level, this.of = 3, this.color, this.label});

  final int level;
  final int of;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimaryFor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < of; i++)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(left: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < level ? c : Colors.transparent,
                  border: Border.all(color: c, width: 1.2),
                ),
              ),
          ],
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(label!, style: AppTypography.caption.copyWith(color: c.withValues(alpha: 0.75), fontSize: 11)),
        ],
      ],
    );
  }
}

/// Pill-shaped segmented tabs. The chosen pill is filled ink (or gold on an
/// ink surface); the rest are outlined.
class PillTabs<T> extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.onInk = false,
    this.onGold = false,
    this.dense = false,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  final bool onInk;
  final bool onGold;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final Color activeFill = onInk ? AppColors.primary : AppColors.ink;
    final Color activeText = onInk ? AppColors.ink : AppColors.cream;
    final Color idleText = onInk
        ? AppColors.cream.withValues(alpha: 0.75)
        : onGold
            ? AppColors.ink
            : AppColors.textSecondaryFor(context);
    final Color idleBorder = onInk
        ? AppColors.cream.withValues(alpha: 0.18)
        : onGold
            ? AppColors.ink.withValues(alpha: 0.25)
            : AppColors.borderFor(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final v in values)
          Material(
            color: v == selected ? activeFill : Colors.transparent,
            shape: StadiumBorder(side: BorderSide(color: v == selected ? activeFill : idleBorder)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onSelected(v),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: dense ? 12 : 16, vertical: dense ? 6 : 8),
                child: Text(
                  label(v),
                  style: AppTypography.body.copyWith(
                    fontSize: dense ? 12 : 13,
                    fontWeight: v == selected ? FontWeight.w700 : FontWeight.w500,
                    color: v == selected ? activeText : idleText,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Round outlined icon button used on cards (↗, ⋮) in the card system.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.child, this.onTap, this.color, this.size = 32, this.tooltip});

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimaryFor(context);
    final button = InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.withValues(alpha: 0.25))),
        child: IconTheme(data: IconThemeData(color: c, size: size * 0.5), child: child),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
