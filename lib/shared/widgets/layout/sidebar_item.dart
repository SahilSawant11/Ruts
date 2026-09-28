import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Sidebar constants – single source of truth.
const double kSidebarRailWidth = 64.0;

// ─── Colours (always dark, never theme-adaptive) ─────────────────────────────
const _kIconIdle   = Color(0x8CFFFFFF); // white @ 55 % — crisp muted grey
// Active pill: primary-tinted background (soft purple glow), matches reference
// The icon itself turns accent-purple to complete the indicator.

/// A single icon-rail nav item. Always renders as icon-only (no label in
/// the layout). Hover state and active state are handled purely visually.
///
/// If you want the label to appear, the parent sidebar uses an [OverlayEntry]
/// or a [Stack]-based expanded panel — the item itself never changes width.
class SidebarItem extends StatefulWidget {
  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final activeBg     = AppColors.primary.withValues(alpha: 0.18);
    final activeBorder = AppColors.primary.withValues(alpha: 0.30);
    const hoverBg      = Color(0xFF252533);

    final iconColor = widget.active ? AppColors.primary : _kIconIdle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: widget.label,
          preferBelow: false,
          waitDuration: const Duration(milliseconds: 500),
          textStyle: AppTypography.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C3A),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: GestureDetector(
            onTap: widget.onTap,
            // Full-width, full-height hit target — keeps hover detection smooth.
            child: SizedBox(
              height: 44,
              width: double.infinity,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  // Fixed compact size → pill never stretches to fill the rail.
                  // 44 wide × 34 tall with radius 17 = perfect stadium capsule.
                  width:  44,
                  height: 34,
                  decoration: BoxDecoration(
                    color: widget.active
                        ? activeBg
                        : (_hovered ? hoverBg : Colors.transparent),
                    // Active: stadium pill (radius = half of height).
                    // Idle:   gentle rounded-rect.
                    borderRadius: BorderRadius.circular(widget.active ? 17 : 8),
                    border: widget.active
                        ? Border.all(color: activeBorder, width: 1)
                        : null,
                  ),
                  child: Center(
                    child: AnimatedScale(
                      scale: _hovered ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      child: Icon(widget.icon, size: 19, color: iconColor),
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

}
