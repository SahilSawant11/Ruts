import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Row with a leading avatar/icon chip, a bold title + muted subtitle,
/// and a trailing value. Used across Dashboard list-style cards.
class InfoListTile extends StatelessWidget {
  const InfoListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.icon,
    this.avatarText,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final IconData? icon;
  final String? avatarText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.sm)),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, size: 17, color: AppColors.textSecondary)
                : Text(
                    avatarText ?? '',
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          Text(trailing, style: AppTypography.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
