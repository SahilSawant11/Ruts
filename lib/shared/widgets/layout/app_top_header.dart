import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
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
        final showSearch = width >= 1420;
        final showLocalMode = width >= 1280;
        final showDate = width >= 1160;
        final showUtilityIcons = width >= 1040;
        final showProfile = width >= 760;
        final showProfileLabel = width >= 1180;
        final showShortcutBadge = width >= 980;
        final compactTitle = width < 1080;
        final showSyncChip = width >= 940;
        final titleFontSize = width < 860 ? 18.0 : 22.0;

        return Container(
          height: 76,
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.glassSurfaceStrongFor(context),
                  border: Border.all(color: AppColors.glassBorderFor(context)),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppColors.cardShadowFor(context),
                ),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () => ref.read(sidebarCollapsedProvider.notifier).state =
                          !ref.read(sidebarCollapsedProvider),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.menu_rounded,
                          color: AppColors.textSecondaryFor(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              moduleTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.h2.copyWith(
                                fontSize: titleFontSize,
                                color: AppColors.textPrimaryFor(context),
                              ),
                            ),
                          ),
                          if (showShortcutBadge && !compactTitle) ...[
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
                    if (showSyncChip)
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
                    if (showUtilityIcons) ...[
                      const SizedBox(width: 6),
                      _iconButton(context, Icons.calculate_outlined),
                      const SizedBox(width: 6),
                      _iconButton(context, Icons.description_outlined),
                    ],
                    if (showProfile) ...[
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
                  ],
                ),
              ),
            ),
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
        color: AppColors.primarySoft.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
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
        color: AppColors.glassSurfaceStrongFor(context),
        border: Border.all(color: AppColors.glassBorderFor(context)),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.18 : 0.06,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
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
          color: isDark ? AppColors.surfaceAltFor(context) : AppColors.glassSurfaceStrongFor(context),
          border: Border.all(color: AppColors.glassBorderFor(context)),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark(context) ? 0.18 : 0.06,
              ),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
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
        color: AppColors.glassSurfaceStrongFor(context),
        border: Border.all(color: AppColors.glassBorderFor(context)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.18 : 0.06,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
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
          color: AppColors.glassSurfaceStrongFor(context),
          border: Border.all(color: AppColors.glassBorderFor(context)),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark(context) ? 0.18 : 0.06,
              ),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
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
