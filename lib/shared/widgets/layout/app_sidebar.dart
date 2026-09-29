import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

import 'sidebar_item.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF1A1A24);
const _kBorder  = Color(0xFF2C2C3A);
const _kMuted   = Color(0x66FFFFFF); // white @ 40 %

/// The fixed-width dark icon rail that lives at the left edge of the shell.
///
/// Layout:
///   • [kSidebarRailWidth] = 64 px, never changes — zero overflow risk.
///   • Top    : brand mark (cocktail glass in a rounded accent tile)
///   • Middle : scrollable nav icons, grouped by section
///   • Bottom : user avatar circle + logout icon
class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location    = GoRouterState.of(context).uri.toString();
    final currentUser = ref.watch(currentUserProvider);
    final initials    = currentUser?.initials ?? 'U';

    return Container(
      width: kSidebarRailWidth,
      margin: const EdgeInsets.fromLTRB(8, 8, 0, 8),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 28,
            offset: const Offset(3, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Brand mark ─────────────────────────────────────────────────
          _BrandMark(),

          // ── Scrollable nav ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                // WORKSPACE
                _GroupDot(),
                SidebarItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  active: location == '/dashboard',
                  onTap: () => context.go('/dashboard'),
                ),
                SidebarItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Sales Bill',
                  active: location == '/sales',
                  onTap: () => context.go('/sales'),
                ),
                SidebarItem(
                  icon: Icons.assignment_return_outlined,
                  label: 'Sales Return',
                  active: location == '/sales-return',
                  onTap: () => context.go('/sales-return'),
                ),
                SidebarItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Purchase Bill',
                  active: location == '/purchase',
                  onTap: () => context.go('/purchase'),
                ),
                SidebarItem(
                  icon: Icons.keyboard_return_rounded,
                  label: 'Purchase Return',
                  active: location == '/purchase-return',
                  onTap: () => context.go('/purchase-return'),
                ),

                // MASTERS
                _GroupDivider(),
                SidebarItem(
                  icon: Icons.local_shipping_outlined,
                  label: 'Supplier Master',
                  active: location == '/supplier',
                  onTap: () => context.go('/supplier'),
                ),
                SidebarItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Material Master',
                  active: location == '/material',
                  onTap: () => context.go('/material'),
                ),
                SidebarItem(
                  icon: Icons.category_outlined,
                  label: 'Category Master',
                  active: location == '/category',
                  onTap: () => context.go('/category'),
                ),
                SidebarItem(
                  icon: Icons.business_outlined,
                  label: 'Manufacturer',
                  active: location == '/manufacturer',
                  onTap: () => context.go('/manufacturer'),
                ),
                SidebarItem(
                  icon: Icons.all_inbox_rounded,
                  label: 'Packaging Master',
                  active: location == '/packaging',
                  onTap: () => context.go('/packaging'),
                ),
                SidebarItem(
                  icon: Icons.dashboard_customize_outlined,
                  label: 'All Masters',
                  active: location == '/masters',
                  onTap: () => context.go('/masters'),
                ),

                // INVENTORY
                _GroupDivider(),
                SidebarItem(
                  icon: Icons.widgets_outlined,
                  label: 'Inventory',
                  active: location == '/inventory',
                  onTap: () => context.go('/inventory'),
                ),

                // REPORTS
                _GroupDivider(),
                SidebarItem(
                  icon: Icons.assessment_outlined,
                  label: 'Reports',
                  active: location == '/reports',
                  onTap: () => context.go('/reports'),
                ),
                SidebarItem(
                  icon: Icons.liquor_outlined,
                  label: 'Brandwise Report',
                  active: location == '/brandwise-report',
                  onTap: () => context.go('/brandwise-report'),
                ),

                // OPERATIONS — hidden when offline-only
                if (!AppConfig.offlineOnly) ...[
                  _GroupDivider(),
                  SidebarItem(
                    icon: Icons.sync_alt_rounded,
                    label: 'Sync Center',
                    active: location == '/sync',
                    onTap: () => context.go('/sync'),
                  ),
                ],
              ],
            ),
          ),

          // ── Bottom: logout + avatar ───────────────────────────────────
          _SidebarBottom(
            initials: initials,
            onLogout: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Cocktail-glass brand mark at the top of the rail.
class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.local_bar_rounded,
            size: 19,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// A subtle dot/line between icon groups (visible at all times, very compact).
class _GroupDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      child: Divider(
        height: 1,
        thickness: 1,
        color: _kBorder,
      ),
    );
  }
}

/// Tiny accent dot that marks the start of the first group.
class _GroupDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 4);
  }
}

/// Avatar circle + logout icon pinned to the bottom.
class _SidebarBottom extends StatelessWidget {
  const _SidebarBottom({
    required this.initials,
    required this.onLogout,
  });

  final String initials;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Divider(height: 1, color: _kBorder),
        const SizedBox(height: 6),
        _LogoutButton(onTap: onLogout),
        const SizedBox(height: 4),
        _AvatarBadge(initials: initials),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _LogoutButton extends StatefulWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Sign out',
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        // Full hit target matches nav item row height, but NOT full rail width.
        child: GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width:  44,
                height: 34,
                decoration: BoxDecoration(
                  color: _hovered
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: _hovered ? Colors.white : _kMuted,
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

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        // Deep purple gradient — professional, not flat primary blue
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5DD3), Color(0xFF4C3DBF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // 10 px matches the nav item pill shape exactly
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF7C6DE0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5DD3).withValues(alpha: 0.35),
            blurRadius: 8,
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
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
