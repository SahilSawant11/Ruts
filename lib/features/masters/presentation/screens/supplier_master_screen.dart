import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../widgets/supplier_form_card.dart';

class SupplierMasterScreen extends StatelessWidget {
  const SupplierMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _ScreenHeader(),
            SizedBox(height: AppSpacing.lg),
            SupplierFormCard(),
          ],
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
              Text('Supplier Master', style: AppTypography.h1),
              const SizedBox(height: 4),
              Text('Create & maintain distributor / supplier records.', style: AppTypography.bodyMuted),
            ],
          ),
        ),
        const StatusChip(label: '142 suppliers'),
      ],
    );
  }
}
