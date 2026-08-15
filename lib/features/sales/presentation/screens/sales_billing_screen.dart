import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../data/sales_providers.dart';
import '../widgets/bill_summary_card.dart';
import '../widgets/billing_mode_toggle.dart';
import '../widgets/invoice_details_card.dart';
import '../widgets/item_details_table.dart';
import '../widgets/payment_card.dart';
import '../widgets/scan_add_item_card.dart';

/// Screen widget tree (per project convention, documented before the code):
///
/// AppShell
///   └── SalesBillingScreen (this file's body)
///         └── SingleChildScrollView
///               └── Column
///                     ├── _ScreenHeader (title + Find/Calc/Notepad actions)
///                     ├── BillingModeToggle (F2/F3 segmented control)
///                     └── Row  (main 2-column workspace)
///                           ├── Expanded (flex 2, left column)
///                           │     ├── InvoiceDetailsCard
///                           │     ├── ScanAddItemCard
///                           │     └── ItemDetailsTable
///                           └── SizedBox(width) + SizedBox (flex 1, right column)
///                                 ├── BillSummaryCard
///                                 └── PaymentCard
class SalesBillingScreen extends StatelessWidget {
  const SalesBillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScreenHeader(),
          SizedBox(height: AppSpacing.sm),
          BillingModeToggle(),
          SizedBox(height: AppSpacing.md),
          Expanded(child: _SalesWorkspace()),
        ],
      ),
    );
  }
}

class _SalesWorkspace extends StatelessWidget {
  const _SalesWorkspace();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              InvoiceDetailsCard(compact: true),
              SizedBox(height: AppSpacing.sm),
              ScanAddItemCard(compact: true),
              SizedBox(height: AppSpacing.sm),
              Expanded(child: ItemDetailsTable(expand: true)),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              BillSummaryCard(compact: true),
              SizedBox(height: AppSpacing.sm),
              PaymentCard(compact: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScreenHeader extends ConsumerWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingSyncAsync = ref.watch(pendingSalesSyncCountProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sale / Billing',
                style: AppTypography.h1.copyWith(
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Counter sale — barcode-first entry for fast checkout.',
                style: AppTypography.bodyMuted.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
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
        SecondaryButton(label: 'Find / Edit Sale', icon: Icons.search_rounded, dense: true, onPressed: () {}),
        const SizedBox(width: AppSpacing.sm),
        SecondaryButton(label: 'Calc', icon: Icons.calculate_outlined, dense: true, onPressed: () {}),
        const SizedBox(width: AppSpacing.sm),
        SecondaryButton(label: 'Notepad', icon: Icons.sticky_note_2_outlined, dense: true, onPressed: () {}),
      ],
    );
  }
}
