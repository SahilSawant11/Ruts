import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'brand_logo.dart';
import 'sidebar_item.dart';
import 'sidebar_state.dart';

/// Left navigation. Highlights whichever route is currently active and
/// navigates via GoRouter on tap. Collapses to an icon-only rail when
/// [sidebarCollapsedProvider] is true (toggled from the top header).
class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final collapsed = ref.watch(sidebarCollapsedProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: collapsed ? 76 : 248,
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundFor(context),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: AppColors.borderFor(context),
          ),
          boxShadow: AppColors.isDark(context)
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.72),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _brand(collapsed),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                children: [
                  _sectionLabel(context, 'WORKSPACE', collapsed),
                  SidebarItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Dashboard',
                    collapsed: collapsed,
                    active: location == '/dashboard',
                    onTap: () => context.go('/dashboard'),
                  ),
                  SidebarItem(
                    icon: Icons.point_of_sale_rounded,
                    label: 'Sales Bill',
                    shortcut: 'F3',
                    collapsed: collapsed,
                    active: location == '/sales',
                    onTap: () => context.go('/sales'),
                  ),
                  SidebarItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Purchase Bill',
                    shortcut: 'F2',
                    collapsed: collapsed,
                    active: location == '/purchase',
                    onTap: () => context.go('/purchase'),
                  ),
                  _sectionLabel(context, 'MASTERS', collapsed),
                  SidebarItem(
                    icon: Icons.local_shipping_outlined,
                    label: 'Supplier Master',
                    collapsed: collapsed,
                    active: location == '/supplier',
                    onTap: () => context.go('/supplier'),
                  ),
                  SidebarItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Material Master',
                    collapsed: collapsed,
                    active: location == '/material',
                    onTap: () => context.go('/material'),
                  ),
                  SidebarItem(
                    icon: Icons.dashboard_customize_outlined,
                    label: 'All Masters',
                    collapsed: collapsed,
                    active: location == '/masters',
                    onTap: () => context.go('/masters'),
                  ),
                  _sectionLabel(context, 'INVENTORY', collapsed),
                  SidebarItem(
                    icon: Icons.widgets_outlined,
                    label: 'Inventory',
                    collapsed: collapsed,
                    active: location == '/inventory',
                    onTap: () => context.go('/inventory'),
                  ),
                  _sectionLabel(context, 'REPORTS', collapsed),
                  SidebarItem(
                    icon: Icons.assessment_outlined,
                    label: 'Reports',
                    collapsed: collapsed,
                    active: location == '/reports',
                    onTap: () => context.go('/reports'),
                  ),
                  _sectionLabel(context, 'OPERATIONS', collapsed),
                  SidebarItem(
                    icon: Icons.sync_alt_rounded,
                    label: 'Sync Center',
                    collapsed: collapsed,
                    active: location == '/sync',
                    onTap: () => context.go('/sync'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brand(bool collapsed) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: collapsed
          ? const Center(child: BrandLogo(compact: true, showWordmark: false))
          : const BrandLogo(),
    );
  }

  Widget _sectionLabel(BuildContext context, String text, bool collapsed) {
    if (collapsed) return const SizedBox(height: AppSpacing.sm);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: Text(
        text,
        style: AppTypography.sidebarSection.copyWith(
          color: AppColors.textMutedFor(context),
        ),
      ),
    );
  }
}
