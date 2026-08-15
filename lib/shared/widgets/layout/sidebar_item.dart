import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class SidebarItem extends StatelessWidget {
  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.shortcut,
    this.active = false,
    this.collapsed = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? shortcut;
  final bool active;
  final bool collapsed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final muted = AppColors.textSecondaryFor(context);
        final iconOnly = collapsed || constraints.maxWidth < 170;
        final surface = active
            ? AppColors.primarySoft.withValues(alpha: AppColors.isDark(context) ? 0.20 : 0.92)
            : Colors.transparent;
        const activeColor = AppColors.primary;

        final content = Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: iconOnly ? 0 : 8,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: iconOnly
                  ? Icon(icon, size: 18, color: active ? activeColor : muted)
                  : Row(
                      children: [
                        Icon(icon, size: 17, color: active ? activeColor : muted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.sidebarItem.copyWith(
                              color: active ? activeColor : muted,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: iconOnly ? 12 : AppSpacing.sm, vertical: 1),
          child: iconOnly
              ? Tooltip(
                  message: label,
                  waitDuration: const Duration(milliseconds: 400),
                  child: content,
                )
              : content,
        );
      },
    );
  }
}
