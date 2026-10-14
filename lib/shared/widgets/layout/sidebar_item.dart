import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Sidebar dimensions – single source of truth.
const double kSidebarCollapsedWidth = 68.0;
const double kSidebarExpandedWidth  = 236.0;
const double kSidebarRailWidth      = kSidebarCollapsedWidth;

/// An Apple Music macOS-styled navigation item.
/// Supports both full-width expanded layout (with label & shortcut key badge)
/// and collapsed layout (compact icon rail with rich tooltip).
class SidebarItem extends StatefulWidget {
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
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    // Active & hover styling tailored to light/dark surfaces
    final activeBg = isDark
        ? AppColors.primary.withValues(alpha: 0.22)
        : AppColors.primary.withValues(alpha: 0.12);

    final activeBorderColor = isDark
        ? AppColors.primary.withValues(alpha: 0.35)
        : AppColors.primary.withValues(alpha: 0.20);

    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);

    final idleIconColor = isDark
        ? const Color(0xFFBAC2D6)
        : const Color(0xFF5A5A6E);

    final iconColor = widget.active ? AppColors.primary : idleIconColor;

    final tooltipMessage = widget.shortcut != null
        ? '${widget.label}  (${widget.shortcut})'
        : widget.label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: widget.collapsed ? tooltipMessage : '',
          preferBelow: false,
          waitDuration: const Duration(milliseconds: 350),
          textStyle: AppTypography.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1E202A),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              height: 36,
              decoration: BoxDecoration(
                color: widget.active
                    ? activeBg
                    : (_hovered ? hoverBg : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
                border: widget.active
                    ? Border.all(color: activeBorderColor, width: 1)
                    : null,
              ),
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: 0,
                  maxWidth: kSidebarExpandedWidth - 16,
                  minHeight: 36,
                  maxHeight: 36,
                  child: SizedBox(
                    width: kSidebarExpandedWidth - 16,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Center(
                              child: AnimatedScale(
                                scale: _hovered ? 1.08 : 1.0,
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOut,
                                child: Icon(
                                  widget.icon,
                                  size: 19,
                                  color: iconColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 120),
                              opacity: widget.collapsed ? 0.0 : 1.0,
                              child: Text(
                                widget.label,
                                style: AppTypography.body.copyWith(
                                  fontSize: 13,
                                  fontWeight: widget.active
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: widget.active
                                      ? (isDark
                                          ? const Color(0xFFC4B8FF)
                                          : AppColors.primary)
                                      : AppColors.textPrimaryFor(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (widget.shortcut != null) ...[
                            const SizedBox(width: 6),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 120),
                              opacity: widget.collapsed ? 0.0 : 1.0,
                              child: _buildShortcutBadge(isDark),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutBadge(bool isDark) {
    final badgeBg = widget.active
        ? (isDark
            ? AppColors.primary.withValues(alpha: 0.32)
            : AppColors.primarySoft)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05));

    final badgeTextColor = widget.active
        ? (isDark ? const Color(0xFFD6CEFF) : AppColors.primary)
        : (isDark ? const Color(0xFF8B93A7) : const Color(0xFF7E8494));

    final badgeBorderColor = widget.active
        ? AppColors.primary.withValues(alpha: isDark ? 0.40 : 0.25)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeBorderColor, width: 0.8),
      ),
      child: Text(
        widget.shortcut!,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: badgeTextColor,
        ),
      ),
    );
  }
}

