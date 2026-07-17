import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
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
      width: collapsed ? 76 : 264,
      color: AppColors.shellDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brand(collapsed),
          const Divider(color: AppColors.shellBorder, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                _sectionLabel('WORKSPACE', collapsed),
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
                _sectionLabel('MASTERS', collapsed),
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
                _sectionLabel('INVENTORY', collapsed),
                SidebarItem(
                  icon: Icons.widgets_outlined,
                  label: 'Inventory',
                  collapsed: collapsed,
                  active: location == '/inventory',
                  onTap: () => context.go('/inventory'),
                ),
                _sectionLabel('REPORTS', collapsed),
                SidebarItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Day-wise Report',
                  collapsed: collapsed,
                  active: location == '/reports',
                  onTap: () => context.go('/reports'),
                ),
                SidebarItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Monthly Report',
                  collapsed: collapsed,
                  active: false,
                  onTap: () => context.go('/reports'),
                ),
                SidebarItem(
                  icon: Icons.filter_alt_outlined,
                  label: 'Custom Report',
                  collapsed: collapsed,
                  active: false,
                  onTap: () => context.go('/reports'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brand(bool collapsed) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text('P', style: AppTypography.h2.copyWith(color: Colors.white)),
          ),
          if (!collapsed) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Product 6', style: AppTypography.sidebarItem.copyWith(fontWeight: FontWeight.w700)),
                  Text('Software · POS Suite',
                      style: AppTypography.caption.copyWith(color: AppColors.shellTextMuted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, bool collapsed) {
    if (collapsed) return const SizedBox(height: AppSpacing.sm);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: Text(text, style: AppTypography.sidebarSection),
    );
  }
}
