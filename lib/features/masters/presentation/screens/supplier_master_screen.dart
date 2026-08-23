import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../data/master_import_service.dart';
import '../../data/masters_providers.dart';
import '../widgets/suppliers_table.dart';
import '../widgets/supplier_form_card.dart';

class SupplierMasterScreen extends StatelessWidget {
  const SupplierMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScreenHeader(),
          SizedBox(height: AppSpacing.lg),
          SuppliersTable(),
          SizedBox(height: AppSpacing.lg),
          SupplierFormCard(),
        ],
      ),
    );
  }
}

class _ScreenHeader extends ConsumerStatefulWidget {
  const _ScreenHeader();

  @override
  ConsumerState<_ScreenHeader> createState() => _ScreenHeaderState();
}

class _ScreenHeaderState extends ConsumerState<_ScreenHeader> {
  bool _isImporting = false;

  Future<void> _import() async {
    setState(() => _isImporting = true);
    try {
      final summary = await ref.read(masterImportServiceProvider).pickAndImport(MasterImportTarget.suppliers);
      if (!mounted || summary == null) return;

      ref.invalidate(suppliersListProvider);

      final firstError = summary.errors.isEmpty ? null : summary.errors.first;
      final isError = summary.failed > 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(firstError == null ? summary.message : '${summary.message}\n$firstError'),
          backgroundColor: isError ? AppColors.danger : AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersListProvider);
    final pendingSyncAsync = ref.watch(pendingMastersSyncCountProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supplier Master',
                style: AppTypography.h1.copyWith(
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create & maintain distributor / supplier records.',
                style: AppTypography.bodyMuted.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SecondaryButton(
              label: _isImporting ? 'Importing…' : 'Import Excel',
              icon: Icons.upload_file_rounded,
              dense: true,
              onPressed: _isImporting ? null : _import,
            ),
            const SizedBox(height: 8),
            suppliersAsync.when(
              loading: () => const StatusChip(label: 'Loading…', tone: StatusChipTone.neutral),
              error: (_, __) => const StatusChip(label: 'Could not load', tone: StatusChipTone.neutral),
              data: (suppliers) => StatusChip(label: '${suppliers.length} supplier${suppliers.length == 1 ? '' : 's'}'),
            ),
            const SizedBox(height: 8),
            pendingSyncAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (count) => count > 0
                  ? const StatusChip(label: 'Pending sync', tone: StatusChipTone.neutral)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }
}
