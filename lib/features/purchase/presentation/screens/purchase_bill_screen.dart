import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
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
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PurchaseBillingModeBar(),
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

class _PurchaseBillingModeBar extends ConsumerWidget {
  const _PurchaseBillingModeBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingSyncAsync = ref.watch(pendingPurchaseSyncCountProvider);

    return Row(
      children: [
        const BillingModeToggle(),
        const Spacer(),
        pendingSyncAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (count) => count > 0
              ? const StatusChip(label: 'Queued offline', tone: StatusChipTone.neutral)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
