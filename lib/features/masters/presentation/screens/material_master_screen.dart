import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../../../shared/widgets/layout/app_shell.dart';
import '../widgets/material_details_card.dart';
import '../widgets/packing_rate_table.dart';

class MaterialMasterScreen extends StatelessWidget {
  const MaterialMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      moduleTitle: 'Material',
      moduleShortcutLabel: 'Master · Material',
      statusModuleName: 'Material',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _ScreenHeader(),
            SizedBox(height: AppSpacing.lg),
            MaterialDetailsCard(),
            SizedBox(height: AppSpacing.lg),
            PackingRateTable(),
          ],
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Material Entry', style: AppTypography.h1),
              const SizedBox(height: 4),
              Text('Material master with multi-packing rate list.', style: AppTypography.bodyMuted),
            ],
          ),
        ),
        const StatusChip(label: 'GST integrated pricing', tone: StatusChipTone.neutral),
      ],
    );
  }
}
