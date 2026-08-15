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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1280;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ScreenHeader(),
              const SizedBox(height: AppSpacing.sm),
              const BillingModeToggle(),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: desktop
                    ? const _DesktopPurchaseWorkspace()
                    : const _StackedPurchaseWorkspace(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DesktopPurchaseWorkspace extends StatelessWidget {
  const _DesktopPurchaseWorkspace();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              BillDetailsCard(compact: true),
              SizedBox(height: AppSpacing.sm),
              ExtraChargesTotalsCard(compact: true),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: PurchaseItemTable(expand: true),
        ),
      ],
    );
  }
}

class _StackedPurchaseWorkspace extends StatelessWidget {
  const _StackedPurchaseWorkspace();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BillDetailsCard(compact: true),
        SizedBox(height: AppSpacing.sm),
        Expanded(child: PurchaseItemTable(expand: true)),
        SizedBox(height: AppSpacing.sm),
        ExtraChargesTotalsCard(compact: true),
      ],
    );
  }
}

class _ScreenHeader extends ConsumerWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingSyncAsync = ref.watch(pendingPurchaseSyncCountProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: compact ? constraints.maxWidth : constraints.maxWidth - 240,
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
                  ? const StatusChip(label: 'Queued offline', tone: StatusChipTone.neutral)
                  : const SizedBox.shrink(),
            ),
            SecondaryButton(label: 'Calc', icon: Icons.calculate_outlined, dense: true, onPressed: () {}),
            SecondaryButton(label: 'Notepad', icon: Icons.sticky_note_2_outlined, dense: true, onPressed: () {}),
          ],
        );
      },
    );
  }
}
