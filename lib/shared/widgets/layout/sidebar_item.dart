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
        final muted = AppColors.shellTextMutedFor(context);
        final iconOnly = collapsed || constraints.maxWidth < 150;

        final content = Material(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: iconOnly ? 0 : 10, vertical: 10),
              child: iconOnly
                  ? Icon(icon, size: 18, color: active ? Colors.white : muted)
                  : Row(
                      children: [
                        Icon(icon, size: 17, color: active ? Colors.white : muted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.sidebarItem.copyWith(
                              color: active ? Colors.white : muted,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (shortcut != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            shortcut!,
                            style: AppTypography.mono.copyWith(
                              fontSize: 10.5,
                              color: active ? Colors.white70 : muted,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        );

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: iconOnly ? 12 : AppSpacing.sm, vertical: 2),
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
