import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../data/masters_providers.dart';
import '../widgets/categories_table.dart';
import '../widgets/category_form_card.dart';

class CategoryMasterScreen extends StatelessWidget {
  const CategoryMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScreenHeader(),
          SizedBox(height: AppSpacing.lg),
          CategoriesTable(),
          SizedBox(height: AppSpacing.lg),
          CategoryFormCard(),
        ],
      ),
    );
  }
}

class _ScreenHeader extends ConsumerWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category Master',
                style: AppTypography.h1.copyWith(color: AppColors.textPrimaryFor(context)),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage the category list used across materials, sales, purchase and inventory.',
                style: AppTypography.bodyMuted.copyWith(color: AppColors.textSecondaryFor(context)),
              ),
            ],
          ),
        ),
        categoriesAsync.when(
          loading: () => const StatusChip(label: 'Loading…', tone: StatusChipTone.neutral),
          error: (_, __) => const StatusChip(label: 'Could not load', tone: StatusChipTone.neutral),
          data: (categories) => StatusChip(label: '${categories.length} category${categories.length == 1 ? '' : 'ies'}'),
        ),
      ],
    );
  }
}
