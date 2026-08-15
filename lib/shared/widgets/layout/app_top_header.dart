import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/sync/data/sync_providers.dart';
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
    final syncOverviewAsync = ref.watch(syncOverviewProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showSearch = width >= 1120;
        final showLocalMode = width >= 980;
        final showDate = width >= 900;
        final showProfileLabel = width >= 760;
        final compactTitle = width < 820;

        return Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.backgroundFor(context),
            border: Border(bottom: BorderSide(color: AppColors.borderFor(context))),
          ),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: () => ref.read(sidebarCollapsedProvider.notifier).state =
                    !ref.read(sidebarCollapsedProvider),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.menu_rounded,
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        moduleTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h2,
                      ),
                    ),
                    if (!compactTitle) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _pillBadge(moduleShortcutLabel),
                    ],
                  ],
                ),
              ),
              if (showSearch) ...[
                const SizedBox(width: AppSpacing.lg),
                const SizedBox(width: 240, child: SearchField()),
              ],
              const Spacer(),
              syncOverviewAsync.when(
                loading: () => const StatusChip(label: 'Sync…', tone: StatusChipTone.neutral),
                error: (_, __) => const StatusChip(label: 'Sync unknown', tone: StatusChipTone.neutral),
                data: (overview) => StatusChip(
                  label: overview.failed > 0
                      ? '${overview.failed} failed'
                      : overview.total > 0
                          ? '${overview.total} queued'
                          : 'Sync clean',
                  tone: overview.failed > 0 ? StatusChipTone.dark : StatusChipTone.neutral,
                ),
              ),
              if (showLocalMode) ...[
                const SizedBox(width: AppSpacing.xs),
                const StatusChip(
                  label: 'Local-first mode',
                  tone: StatusChipTone.neutral,
                  icon: Icons.storage_rounded,
                ),
              ],
              if (showDate) ...[
                const SizedBox(width: AppSpacing.xs),
                StatusChip(
                  label: _todayLabel(),
                  tone: StatusChipTone.neutral,
                  icon: Icons.calendar_today_outlined,
                ),
              ],
              const SizedBox(width: AppSpacing.sm),
              _themeButton(
                context: context,
                isDark: isDark,
                themeMode: themeMode,
                onTap: () => ref.read(appThemeModeProvider.notifier).state =
                    isDark ? ThemeMode.light : ThemeMode.dark,
              ),
              const SizedBox(width: 6),
              _iconButton(context, Icons.calculate_outlined),
              const SizedBox(width: 6),
              _iconButton(context, Icons.description_outlined),
              const SizedBox(width: 6),
              _logoutButton(context, ref),
              const SizedBox(width: AppSpacing.sm),
              _profile(
                context,
                showLabel: showProfileLabel,
                username: currentUser?.username ?? 'guest',
                roleLabel: currentUser?.roleLabel ?? 'Offline User',
                initials: currentUser?.initials ?? 'GU',
              ),
            ],
          ),
        );
      },
    );
  }

  String _todayLabel() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year}';
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

  Widget _iconButton(BuildContext context, IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: AppColors.borderFor(context)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        icon,
        size: 18,
        color: AppColors.textSecondaryFor(context),
      ),
    );
  }

  Widget _themeButton({
    required BuildContext context,
    required bool isDark,
    required ThemeMode themeMode,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceAltFor(context) : Colors.transparent,
          border: Border.all(color: AppColors.borderFor(context)),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          size: 18,
          color: AppColors.textSecondaryFor(context),
        ),
      ),
    );
  }

  Widget _profile(
    BuildContext context, {
    required bool showLabel,
    required String username,
    required String roleLabel,
    required String initials,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderFor(context)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          if (showLabel) ...[
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryFor(context),
                    ),
                  ),
                  Text(
                    roleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _logoutButton(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => ref.read(authControllerProvider.notifier).signOut(),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderFor(context)),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          Icons.logout_rounded,
          size: 18,
          color: AppColors.textSecondaryFor(context),
        ),
      ),
    );
  }
}
