import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/tag_pill.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class MasterTile extends StatelessWidget {
  const MasterTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.comingSoon = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: comingSoon ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Opacity(
        opacity: comingSoon ? 0.55 : 1,
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 19, color: AppColors.primary),
                  ),
                  if (comingSoon) const TagPill(label: 'SOON', tone: TagPillTone.neutral),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: AppTypography.sectionTitle),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.bodyMuted),
            ],
          ),
        ),
      ),
    );
  }
}
