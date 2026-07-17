import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../badges/status_chip.dart';
import '../inputs/search_field.dart';
import 'sidebar_state.dart';

/// Top bar shown on every screen: hamburger (toggles sidebar collapse),
/// current module title + its shortcut, global search, online/weather/
/// date chips, quick icon actions and the signed-in user.
class AppTopHeader extends ConsumerWidget {
  const AppTopHeader({
    super.key,
    required this.moduleTitle,
    required this.moduleShortcutLabel,
  });

  final String moduleTitle;
  final String moduleShortcutLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: () => ref.read(sidebarCollapsedProvider.notifier).state =
                !ref.read(sidebarCollapsedProvider),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.menu_rounded, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(moduleTitle, style: AppTypography.h2),
          const SizedBox(width: AppSpacing.xs),
          _pillBadge(moduleShortcutLabel),
          const SizedBox(width: AppSpacing.lg),
          const SearchField(),
          const Spacer(),
          const StatusChip(label: 'Online'),
          const SizedBox(width: AppSpacing.xs),
          const StatusChip(label: '30°C · Mostly cloudy', tone: StatusChipTone.neutral, icon: Icons.wb_cloudy_outlined),
          const SizedBox(width: AppSpacing.xs),
          const StatusChip(label: '28-Jun-2026', tone: StatusChipTone.neutral, icon: Icons.calendar_today_outlined),
          const SizedBox(width: AppSpacing.sm),
          _iconButton(Icons.calculate_outlined),
          const SizedBox(width: 6),
          _iconButton(Icons.description_outlined),
          const SizedBox(width: AppSpacing.sm),
          _profile(),
        ],
      ),
    );
  }

  Widget _pillBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: 18, color: AppColors.textSecondary),
    );
  }

  Widget _profile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text('AD', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('admin', style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
              Text('Store Manager', style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}
