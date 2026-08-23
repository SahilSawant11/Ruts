import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../data/masters_providers.dart';
import '../widgets/manufacturer_form_card.dart';
import '../widgets/manufacturers_table.dart';

class ManufacturerMasterScreen extends StatelessWidget {
  const ManufacturerMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScreenHeader(),
          SizedBox(height: AppSpacing.lg),
          ManufacturersTable(),
          SizedBox(height: AppSpacing.lg),
          ManufacturerFormCard(),
        ],
      ),
    );
  }
}

class _ScreenHeader extends ConsumerWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manufacturersAsync = ref.watch(manufacturersListProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manufacturer Master',
                style: AppTypography.h1.copyWith(color: AppColors.textPrimaryFor(context)),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage the manufacturer list used across materials and inventory.',
                style: AppTypography.bodyMuted.copyWith(color: AppColors.textSecondaryFor(context)),
              ),
            ],
          ),
        ),
        manufacturersAsync.when(
          loading: () => const StatusChip(label: 'Loading…', tone: StatusChipTone.neutral),
          error: (_, __) => const StatusChip(label: 'Could not load', tone: StatusChipTone.neutral),
          data: (manufacturers) => StatusChip(label: '${manufacturers.length} manufacturer${manufacturers.length == 1 ? '' : 's'}'),
        ),
      ],
    );
  }
}
