import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_selector/file_selector.dart';
import '../../../../core/local/backup_service.dart';
import '../../../../core/theme/app_colors.dart';
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
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.5,
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
          const MasterTile(
            icon: AppIcons.badge,
            title: 'User Management',
            subtitle: 'Roles & permissions',
            comingSoon: true,
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
            subtitle: 'Backup database',
            onTap: () => _showBackupDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final backup = BackupService(db);

    final folder = await getDirectoryPath(
      confirmButtonText: 'Save Backup Here',
    );
    if (folder == null) return;

    try {
      final path = await backup.backupNow(folder);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup saved: ${path.split('/').last}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup failed: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
