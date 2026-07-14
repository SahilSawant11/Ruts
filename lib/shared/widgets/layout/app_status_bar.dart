import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Thin dark strip fixed to the bottom of the app shell with session
/// info on the left and quick shortcut hints on the right.
class AppStatusBar extends StatelessWidget {
  const AppStatusBar({super.key, required this.moduleName});

  final String moduleName;

  @override
  Widget build(BuildContext context) {
    final muted = AppTypography.caption.copyWith(color: AppColors.shellTextMuted);
    return Container(
      height: 34,
      color: AppColors.shellDark,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          _dot(),
          const SizedBox(width: 6),
          Text('admin · online', style: muted),
          const SizedBox(width: AppSpacing.md),
          Text('Module: $moduleName', style: muted),
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.shellTextMuted),
          const SizedBox(width: 5),
          Text('28-Jun-2026, Sunday', style: muted),
          const Spacer(),
          Text('F2-F3 switch billing · F10 delete · F8 save', style: muted),
          const SizedBox(width: AppSpacing.md),
          _dot(),
          const SizedBox(width: 6),
          Text('Live', style: muted),
          const SizedBox(width: AppSpacing.md),
          Text('Product 6 Software v8.4', style: muted),
        ],
      ),
    );
  }

  Widget _dot() => Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
      );
}
