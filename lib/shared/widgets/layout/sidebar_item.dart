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
    final content = Material(
      color: active ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 10, vertical: 10),
          child: collapsed
              ? Icon(icon, size: 18, color: active ? Colors.white : AppColors.shellTextMuted)
              : Row(
                  children: [
                    Icon(icon, size: 17, color: active ? Colors.white : AppColors.shellTextMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTypography.sidebarItem.copyWith(
                          color: active ? Colors.white : AppColors.shellTextMuted,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (shortcut != null)
                      Text(
                        shortcut!,
                        style: AppTypography.mono.copyWith(
                          fontSize: 10.5,
                          color: active ? Colors.white70 : AppColors.shellTextMuted,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : AppSpacing.sm, vertical: 2),
      child: collapsed ? Tooltip(message: label, waitDuration: const Duration(milliseconds: 400), child: content) : content,
    );
  }
}
