import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
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
    final licenseHoldersAsync = ref.watch(licenseHoldersListProvider);

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
      // Fixed-height tiles (content is ~110px; aspect-ratio tiles were 200px
      // of mostly empty space) and as many columns as fit.
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320,
          mainAxisExtent: 136,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        children: [
          MasterTile(
            icon: AppIcons.suppliers,
            title: 'Supplier Master',
            subtitle: countLabel(suppliersAsync, 'supplier'),
            onTap: () => context.go('/supplier'),
          ),
          MasterTile(
            icon: AppIcons.materials,
            title: 'Material Master',
            subtitle: countLabel(materialsAsync, 'material'),
            onTap: () => context.go('/material'),
          ),
          MasterTile(
            icon: AppIcons.categories,
            title: 'Category Master',
            subtitle: countLabel(categoriesAsync, 'category'),
            onTap: () => context.go('/category'),
          ),
          MasterTile(
            icon: AppIcons.manufacturers,
            title: 'Manufacturer Master',
            subtitle: countLabel(manufacturersAsync, 'manufacturer'),
            onTap: () => context.go('/manufacturer'),
          ),
          MasterTile(
            icon: AppIcons.packagings,
            title: 'Packaging Master',
            subtitle: countLabel(packingsAsync, 'packaging'),
            onTap: () => context.go('/packaging'),
          ),
          const MasterTile(
            icon: AppIcons.people,
            title: 'Customer Master',
            subtitle: 'Credit accounts & balances',
            comingSoon: true,
          ),
          MasterTile(
            icon: AppIcons.badge,
            title: 'User Management',
            subtitle: 'Roles & permissions',
            onTap: () => context.go('/settings'),
          ),
          const MasterTile(
            icon: AppIcons.receipt,
            title: 'Tax / GST Master',
            subtitle: 'Slab configuration',
            comingSoon: true,
          ),
          MasterTile(
            icon: AppIcons.licenseHolders,
            title: 'License Holder Master',
            subtitle: countLabel(licenseHoldersAsync, 'permit'),
            onTap: () => context.go('/license-holder'),
          ),
          MasterTile(
            icon: AppIcons.settings,
            title: 'App Settings',
            subtitle: 'Backup, restore & users',
            onTap: () => context.go('/settings'),
          ),
        ],
      ),
    );
  }
}
