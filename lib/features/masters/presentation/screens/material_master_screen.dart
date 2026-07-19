import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../data/masters_providers.dart';
import '../widgets/material_form_card.dart';

class MaterialMasterScreen extends StatelessWidget {
  const MaterialMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ScreenHeader(),
          SizedBox(height: AppSpacing.lg),
          MaterialFormCard(),
        ],
      ),
    );
  }
}

class _ScreenHeader extends ConsumerWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsListProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Material Master', style: AppTypography.h1),
              const SizedBox(height: 4),
              Text('Real catalog, keyed by Local Item Code.', style: AppTypography.bodyMuted),
            ],
          ),
        ),
        materialsAsync.when(
          loading: () => const StatusChip(label: 'Loading…', tone: StatusChipTone.neutral),
          error: (_, __) => const StatusChip(label: 'Could not load', tone: StatusChipTone.neutral),
          data: (materials) => StatusChip(label: '${materials.length} material${materials.length == 1 ? '' : 's'}'),
        ),
      ],
    );
  }
}
