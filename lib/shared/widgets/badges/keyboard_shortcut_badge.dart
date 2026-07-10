import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Small pill showing a keyboard shortcut, e.g. "F8", "Ctrl K".
/// Used inside buttons, fields and the status bar so shortcuts
/// stay visually consistent everywhere.
class KeyboardShortcutBadge extends StatelessWidget {
  const KeyboardShortcutBadge({
    super.key,
    required this.label,
    this.onLight = false,
  });

  final String label;

  /// True when the badge sits on a light/white surface (needs its own
  /// gray chip); false when it sits on a colored button and should be
  /// a translucent overlay instead.
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: onLight ? AppColors.surfaceAlt : Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppRadius.sm - 2),
        border: onLight ? Border.all(color: AppColors.border) : null,
      ),
      child: Text(
        label,
        style: AppTypography.mono.copyWith(
          fontSize: 10.5,
          color: onLight ? AppColors.textSecondary : Colors.white,
        ),
      ),
    );
  }
}
