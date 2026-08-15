import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
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

class _ScreenHeader extends ConsumerWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
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
