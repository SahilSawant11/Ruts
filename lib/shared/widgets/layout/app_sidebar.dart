import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'sidebar_item.dart';

/// Static, dummy-data left navigation. Selection state (which module is
/// active) will move to a Riverpod provider once routing wires up more
/// than one screen.
class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      color: AppColors.shellDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brand(),
          const Divider(color: AppColors.shellBorder, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                _sectionLabel('WORKSPACE'),
                const SidebarItem(icon: Icons.grid_view_rounded, label: 'Dashboard'),
                const SidebarItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Sales Bill',
                  shortcut: 'F3',
                  active: true,
                ),
                const SidebarItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Purchase Bill',
                  shortcut: 'F2',
                ),
                _sectionLabel('MASTERS'),
                const SidebarItem(icon: Icons.local_shipping_outlined, label: 'Supplier Master'),
                const SidebarItem(icon: Icons.inventory_2_outlined, label: 'Material Master'),
                const SidebarItem(icon: Icons.dashboard_customize_outlined, label: 'All Masters'),
                _sectionLabel('INVENTORY'),
                const SidebarItem(icon: Icons.widgets_outlined, label: 'Inventory'),
                _sectionLabel('REPORTS'),
                const SidebarItem(icon: Icons.calendar_today_outlined, label: 'Day-wise Report'),
                const SidebarItem(icon: Icons.bar_chart_rounded, label: 'Monthly Report'),
                const SidebarItem(icon: Icons.filter_alt_outlined, label: 'Custom Report'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brand() {
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
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product 6', style: AppTypography.sidebarItem.copyWith(fontWeight: FontWeight.w700)),
              Text('Software · POS Suite',
                  style: AppTypography.caption.copyWith(color: AppColors.shellTextMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: Text(text, style: AppTypography.sidebarSection),
    );
  }
}
