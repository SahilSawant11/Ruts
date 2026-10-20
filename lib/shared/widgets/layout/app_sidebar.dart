import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_controller.dart';
// import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/dashboard/data/dashboard_providers.dart';
import 'sidebar_item.dart';

/// Apple Music macOS-style navigation sidebar.
///
/// Features:
///   • Full-height docked design with 1px right border (no awkward floating margins).
///   • Pure hover-to-expand: smoothly expands when cursor hovers, collapses on leave.
///   • Clearly categorized sections (Workspace, Masters, Inventory & Reports, System).
///   • Visual POS keyboard shortcut tags (F1–F12) for fast muscle-memory navigation.
///   • Adaptive light / dark appearance matching the app's macOS theme tokens.
///   • Zero overflow or cropped text during transitions.
class AppSidebar extends ConsumerStatefulWidget {
  const AppSidebar({super.key});

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final location    = GoRouterState.of(context).uri.toString();
    final currentUser = ref.watch(currentUserProvider);
    final isDark      = AppColors.isDark(context);

    // Pure hover-to-expand: expanded when hovered, compact rail when not.
    final collapsed = !_isHovered;
    final width     = _isHovered ? kSidebarExpandedWidth : kSidebarCollapsedWidth;

    final sidebarBg = isDark
        ? const Color(0xFF151720)
        : const Color(0xFFF6F6F9);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: width,
        decoration: BoxDecoration(
          color: sidebarBg,
          border: Border(
            right: BorderSide(
              color: AppColors.borderFor(context),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // ── Header (Centered Brand Mark + Wordmark) ─────────────────
            _SidebarHeader(collapsed: collapsed),

            // ── Nav Items ─────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // 1. WORKSPACE
                  _SectionHeader(title: 'Workspace', collapsed: collapsed),
                  SidebarItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Dashboard',
                    shortcut: 'F1',
                    active: location == '/dashboard',
                    collapsed: collapsed,
                    onTap: () {
                      ref.invalidate(dashboardSummaryProvider);
                      context.go('/dashboard');
                      setState(() => _isHovered = false);
                    },
                  ),
                  SidebarItem(
                    icon: Icons.point_of_sale_rounded,
                    label: 'Sales Bill',
                    shortcut: 'F3',
                    active: location == '/sales',
                    collapsed: collapsed,
                    onTap: () {
                      context.go('/sales');
                      setState(() => _isHovered = false);
                    },
                  ),
                  SidebarItem(
                    icon: Icons.assignment_return_outlined,
                    label: 'Sales Return',
                    shortcut: 'F8',
                    active: location == '/sales-return',
                    collapsed: collapsed,
                    onTap: () {
                      context.go('/sales-return');
                      setState(() => _isHovered = false);
                    },
                  ),
                  SidebarItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Purchase Bill',
                    shortcut: 'F2',
                    active: location == '/purchase',
                    collapsed: collapsed,
                    onTap: () {
                      context.go('/purchase');
                      setState(() => _isHovered = false);
                    },
                  ),
                  SidebarItem(
                    icon: Icons.keyboard_return_rounded,
                    label: 'Purchase Return',
                    active: location == '/purchase-return',
                    collapsed: collapsed,
                    onTap: () {
                      context.go('/purchase-return');
                      setState(() => _isHovered = false);
                    },
                  ),

                  // 2. MASTERS
                  _SectionHeader(title: 'Masters', collapsed: collapsed),
                  SidebarItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Material Master',
                    shortcut: 'F4',
                    active: location == '/material',
                    collapsed: collapsed,
                    onTap: () {
                      context.go('/material');
                      setState(() => _isHovered = false);
                    },
                  ),
                  SidebarItem(
                    icon: Icons.category_outlined,
                    label: 'Category Master',
                    shortcut: 'F11',
                    active: location == '/category',
                    collapsed: collapsed,
                    onTap: () {
                      context.go('/category');
                      setState(() => _isHovered = false);
                    },
                  ),
                  SidebarItem(
                    icon: Icons.local_shipping_outlined,
                    label: 'Supplier Master',
                    shortcut: 'F7',
                    active: location == '/supplier',
                    collapsed: collapsed,
                    onTap: () {
                      context.go('/supplier');
                      setState(() => _isHovered = false);
                    },
                  ),
                  SidebarItem(
                    icon: Icons.business_outlined,
                    label: 'Manufacturer',
                    active: location == '/manufacturer',
                    collapsed: collapsed,
                    onTap: () {
                      context.go('/manufacturer');
                      setState(() => _isHovered = false);
                    },
                  ),
                  SidebarItem(
                    icon: Icons.all_inbox_rounded,
                    label: 'Packaging Master',
                    active: location == '/packaging',
                    collapsed: collapsed,
                    onTap: () {
                      context.go('/packaging');
                      setState(() => _isHovered = false);
                    },
                  ),
                  SidebarItem(
                    icon: Icons.badge_outlined,
                    label: 'License Holder',
                    active: location == '/license-holder',
                    collapsed: collapsed,
                    onTap: () {
                      context.go('/license-holder');
                      setState(() => _isHovered = false);
                    },
                  ),
                  SidebarItem(
                    icon: Icons.dashboard_customize_outlined,
                    label: 'All Masters',
                    shortcut: 'F9',
                    active: location == '/masters',
                    collapsed: collapsed,
                    onTap: () {
                      context.go('/masters');
                      setState(() => _isHovered = false);
                    },
                  ),

                  // 3. INVENTORY & REPORTS
                  _SectionHeader(title: 'Inventory & Reports', collapsed: collapsed),
                  SidebarItem(
                    icon: Icons.widgets_outlined,
                    label: 'Inventory',
                    shortcut: 'F5',
                    active: location == '/inventory',
                    collapsed: collapsed,
                    onTap: () {
                      context.go('/inventory');
                      setState(() => _isHovered = false);
                    },
                  ),
                  SidebarItem(
                    icon: Icons.assessment_outlined,
                    label: 'SCM Daily Sale',
                    shortcut: 'F6',
                    active: location == '/reports',
                    collapsed: collapsed,
                    onTap: () {
                      context.go('/reports');
                      setState(() => _isHovered = false);
                    },
                  ),
                  SidebarItem(
                    icon: Icons.liquor_outlined,
                    label: 'Brandwise Report',
                    shortcut: 'F10',
                    active: location == '/brandwise-report',
                    collapsed: collapsed,
                    onTap: () {
                      context.go('/brandwise-report');
                      setState(() => _isHovered = false);
                    },
                  ),

                  // 4. SYSTEM (Sync Center commented out for offline MVP)
                  // if (!AppConfig.offlineOnly) ...[
                  //   _SectionHeader(title: 'System', collapsed: collapsed),
                  //   SidebarItem(
                  //     icon: Icons.sync_alt_rounded,
                  //     label: 'Sync Center',
                  //     shortcut: 'F12',
                  //     active: location == '/sync',
                  //     collapsed: collapsed,
                  //     onTap: () {
                  //       context.go('/sync');
                  //       setState(() => _isHovered = false);
                  //     },
                  //   ),
                  // ],
                ],
              ),
            ),

            // ── Footer (User profile / Sign out) ──────────────────────────
            _SidebarFooter(
              collapsed: collapsed,
              initials: currentUser?.initials ?? 'GU',
              username: currentUser?.username ?? 'Guest User',
              roleLabel: currentUser?.roleLabel ?? 'Offline Mode',
              onLogout: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.collapsed});
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderFor(context),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: 0,
          maxWidth: kSidebarExpandedWidth,
          minHeight: 60,
          maxHeight: 60,
          child: SizedBox(
            width: kSidebarExpandedWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const _CocktailMark(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 140),
                      opacity: collapsed ? 0.0 : 1.0,
                      curve: Curves.easeOut,
                      child: ClipRect(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Caskly',
                              style: AppTypography.sectionTitle.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                            Text(
                              'Liquor POS',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondaryFor(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CocktailMark extends StatelessWidget {
  const _CocktailMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primarySoftFor(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.local_bar_rounded,
        size: 19,
        color: AppColors.primary,
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.collapsed});
  final String title;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Divider(
          height: 1,
          thickness: 1,
          color: AppColors.borderFor(context),
        ),
      );
    }

    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Text(
          title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textMutedFor(context),
          ),
        ),
      ),
    );
  }
}

// ─── Footer ──────────────────────────────────────────────────────────────────

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({
    required this.collapsed,
    required this.initials,
    required this.username,
    required this.roleLabel,
    required this.onLogout,
  });

  final bool collapsed;
  final String initials;
  final String username;
  final String roleLabel;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderFor(context),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: 0,
          maxWidth: kSidebarExpandedWidth,
          minHeight: 44,
          maxHeight: 44,
          child: SizedBox(
            width: kSidebarExpandedWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 19),
              child: Row(
                children: [
                  _AvatarBadge(initials: initials, size: 30),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 140),
                      opacity: collapsed ? 0.0 : 1.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            username,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: AppColors.textPrimaryFor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            roleLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMutedFor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 140),
                    opacity: collapsed ? 0.0 : 1.0,
                    child: _LogoutIconButton(onTap: onLogout),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.initials, this.size = 34});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF5A46D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.28),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _LogoutIconButton extends StatefulWidget {
  const _LogoutIconButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_LogoutIconButton> createState() => _LogoutIconButtonState();
}

class _LogoutIconButtonState extends State<_LogoutIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Tooltip(
      message: 'Sign out',
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hovered
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.logout_rounded,
              size: 17,
              color: _hovered
                  ? AppColors.danger
                  : AppColors.textMutedFor(context),
            ),
          ),
        ),
      ),
    );
  }
}


