import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/masters_providers.dart';
import '../widgets/master_tile.dart';

class AllMastersScreen extends ConsumerWidget {
  const AllMastersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersListProvider);
    final materialsAsync = ref.watch(materialsListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final manufacturersAsync = ref.watch(manufacturersListProvider);
    final packingsAsync = ref.watch(packingsListProvider);

    String countLabel(AsyncValue<List<dynamic>> async, String noun) {
      final plural = noun.endsWith('y') ? '${noun.substring(0, noun.length - 1)}ies' : '${noun}s';
      return async.when(
        data: (list) => '${list.length} ${list.length == 1 ? noun : plural}',
        loading: () => 'Loading…',
        error: (_, __) => 'Could not load',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Masters',
            style: AppTypography.h1.copyWith(
              color: AppColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Every master data module in one place.',
            style: AppTypography.bodyMuted.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
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
                subtitle: countLabel(suppliersAsync, 'supplier'),
                onTap: () => context.go('/supplier'),
              ),
              MasterTile(
                icon: Icons.inventory_2_outlined,
                title: 'Material Master',
                subtitle: countLabel(materialsAsync, 'material'),
                onTap: () => context.go('/material'),
              ),
              MasterTile(
                icon: Icons.category_outlined,
                title: 'Category Master',
                subtitle: countLabel(categoriesAsync, 'category'),
                onTap: () => context.go('/category'),
              ),
              MasterTile(
                icon: Icons.business_outlined,
                title: 'Manufacturer Master',
                subtitle: countLabel(manufacturersAsync, 'manufacturer'),
                onTap: () => context.go('/manufacturer'),
              ),
              MasterTile(
                icon: Icons.all_inbox_rounded,
                title: 'Packaging Master',
                subtitle: countLabel(packingsAsync, 'packaging'),
                onTap: () => context.go('/packaging'),
              ),
              const MasterTile(
                icon: Icons.people_outline_rounded,
                title: 'Customer Master',
                subtitle: 'Credit accounts & balances',
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
    );
  }
}
