import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../data/masters_providers.dart';
import '../widgets/packaging_form_card.dart';
import '../widgets/packagings_table.dart';

class PackagingMasterScreen extends StatelessWidget {
  const PackagingMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScreenHeader(),
          SizedBox(height: AppSpacing.lg),
          PackagingsTable(),
          SizedBox(height: AppSpacing.lg),
          PackagingFormCard(),
        ],
      ),
    );
  }
}

class _ScreenHeader extends ConsumerWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packingsAsync = ref.watch(packingsListProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Packaging Master',
                style: AppTypography.h1.copyWith(color: AppColors.textPrimaryFor(context)),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage the standard packaging sizes and types used across materials and inventory.',
                style: AppTypography.bodyMuted.copyWith(color: AppColors.textSecondaryFor(context)),
              ),
            ],
          ),
        ),
        packingsAsync.when(
          loading: () => const StatusChip(label: 'Loading…', tone: StatusChipTone.neutral),
          error: (_, __) => const StatusChip(label: 'Could not load', tone: StatusChipTone.neutral),
          data: (packings) => StatusChip(label: '${packings.length} packaging${packings.length == 1 ? '' : 's'}'),
        ),
      ],
    );
  }
}
