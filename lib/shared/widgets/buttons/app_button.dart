import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../badges/keyboard_shortcut_badge.dart';

enum AppButtonVariant { primary, secondary, success, danger, dangerOutline }

/// Single button component backing PrimaryButton / SecondaryButton /
/// SuccessButton / DangerButton. Keeping one implementation means every
/// button in the app shares padding, radius and shortcut-badge layout.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.shortcut,
    this.expand = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final String? shortcut;
  final bool expand;
  final bool dense;

  _ButtonColors get _colors {
    switch (variant) {
      case AppButtonVariant.primary:
        return _ButtonColors(AppColors.primary, Colors.white, null);
      case AppButtonVariant.success:
        return _ButtonColors(AppColors.success, Colors.white, null);
      case AppButtonVariant.danger:
        return _ButtonColors(AppColors.danger, Colors.white, null);
      case AppButtonVariant.dangerOutline:
        return _ButtonColors(AppColors.background, AppColors.danger, AppColors.dangerSoft);
      case AppButtonVariant.secondary:
        return _ButtonColors(AppColors.background, AppColors.textPrimary, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    final needsBorder = variant == AppButtonVariant.secondary ||
        variant == AppButtonVariant.dangerOutline;
    final vPad = dense ? 10.0 : 13.0;

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: colors.fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: colors.fg,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (shortcut != null) ...[
          const SizedBox(width: AppSpacing.xs),
          KeyboardShortcutBadge(
            label: shortcut!,
            onLight: variant == AppButtonVariant.secondary ||
                variant == AppButtonVariant.dangerOutline,
          ),
        ],
      ],
    );

    return Material(
      color: colors.bg,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: vPad),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: needsBorder
                ? Border.all(
                    color: variant == AppButtonVariant.dangerOutline
                        ? AppColors.danger.withOpacity(0.35)
                        : AppColors.border,
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ButtonColors {
  const _ButtonColors(this.bg, this.fg, this.tint);
  final Color bg;
  final Color fg;
  final Color? tint;
}
