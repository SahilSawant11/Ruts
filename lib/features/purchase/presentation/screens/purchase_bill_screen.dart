import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../sales/presentation/widgets/billing_mode_toggle.dart';
import '../../data/purchase_providers.dart';
import '../widgets/bill_details_card.dart';
import '../widgets/extra_charges_totals_card.dart';
import '../widgets/purchase_item_table.dart';

/// Widget tree:
/// AppShell
///   └── PurchaseBillScreen body
///         └── SingleChildScrollView → Column
///               ├── _ScreenHeader (title + Calc/Notepad actions)
///               ├── BillingModeToggle (shared F2/F3 toggle, reused from Sales)
///               ├── BillDetailsCard
///               ├── PurchaseItemTable
///               └── ExtraChargesTotalsCard
class PurchaseBillScreen extends StatelessWidget {
  const PurchaseBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _ScreenHeader(),
            SizedBox(height: AppSpacing.md),
            BillingModeToggle(),
            SizedBox(height: AppSpacing.lg),
            BillDetailsCard(),
            SizedBox(height: AppSpacing.lg),
            PurchaseItemTable(),
            SizedBox(height: AppSpacing.lg),
            ExtraChargesTotalsCard(),
          ],
        ),
      );
  }
}

class _ScreenHeader extends ConsumerWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingSyncAsync = ref.watch(pendingPurchaseSyncCountProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Purchase Bill', style: AppTypography.h1),
              const SizedBox(height: 4),
              Text('Supplier inward entry with tax & extra charges.', style: AppTypography.bodyMuted),
            ],
          ),
        ),
        pendingSyncAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (count) => count > 0
              ? const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: StatusChip(label: 'Queued offline', tone: StatusChipTone.neutral),
                )
              : const SizedBox.shrink(),
        ),
        SecondaryButton(label: 'Calc', icon: Icons.calculate_outlined, onPressed: () {}),
        const SizedBox(width: AppSpacing.sm),
        SecondaryButton(label: 'Notepad', icon: Icons.sticky_note_2_outlined, onPressed: () {}),
      ],
    );
  }
}
