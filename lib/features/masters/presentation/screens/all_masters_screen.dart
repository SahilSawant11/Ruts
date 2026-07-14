import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_shell.dart';
import '../widgets/master_tile.dart';

class AllMastersScreen extends StatelessWidget {
  const AllMastersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      moduleTitle: 'Masters',
      moduleShortcutLabel: 'All Masters',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('All Masters', style: AppTypography.h1),
            const SizedBox(height: 4),
            Text('Every master data module in one place.', style: AppTypography.bodyMuted),
            const SizedBox(height: AppSpacing.lg),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.5,
              children: [
                MasterTile(
                  icon: Icons.local_shipping_outlined,
                  title: 'Supplier Master',
                  subtitle: '142 suppliers',
                  onTap: () => context.go('/supplier'),
                ),
                MasterTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Material Master',
                  subtitle: 'GST-integrated pricing',
                  onTap: () => context.go('/material'),
                ),
                const MasterTile(
                  icon: Icons.people_outline_rounded,
                  title: 'Customer Master',
                  subtitle: 'Credit accounts & balances',
                  comingSoon: true,
                ),
                const MasterTile(
                  icon: Icons.category_outlined,
                  title: 'Category Master',
                  subtitle: 'Whisky, Beer, Wine, Rum...',
                  comingSoon: true,
                ),
                const MasterTile(
                  icon: Icons.badge_outlined,
                  title: 'User Management',
                  subtitle: 'Roles & permissions',
                  comingSoon: true,
                ),
                const MasterTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Tax / GST Master',
                  subtitle: 'Slab configuration',
                  comingSoon: true,
                ),
                const MasterTile(
                  icon: Icons.store_outlined,
                  title: 'Store License',
                  subtitle: 'License no., validity',
                  comingSoon: true,
                ),
                const MasterTile(
                  icon: Icons.settings_outlined,
                  title: 'App Settings',
                  subtitle: 'Printer, backup, theme',
                  comingSoon: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
