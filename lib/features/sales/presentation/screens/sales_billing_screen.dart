import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
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
    return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ScreenHeader(),
            const SizedBox(height: AppSpacing.md),
            const BillingModeToggle(),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: const [
                      InvoiceDetailsCard(),
                      SizedBox(height: AppSpacing.lg),
                      ScanAddItemCard(),
                      SizedBox(height: AppSpacing.lg),
                      ItemDetailsTable(),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    children: const [
                      BillSummaryCard(),
                      SizedBox(height: AppSpacing.lg),
                      PaymentCard(),
                    ],
                  ),
                ),
              ],
            ),
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
              Text('Sale / Billing', style: AppTypography.h1),
              const SizedBox(height: 4),
              Text(
                'Counter sale — barcode-first entry for fast checkout.',
                style: AppTypography.bodyMuted,
              ),
            ],
          ),
        ),
        SecondaryButton(label: 'Find / Edit Sale', icon: Icons.search_rounded, onPressed: () {}),
        const SizedBox(width: AppSpacing.sm),
        SecondaryButton(label: 'Calc', icon: Icons.calculate_outlined, onPressed: () {}),
        const SizedBox(width: AppSpacing.sm),
        SecondaryButton(label: 'Notepad', icon: Icons.sticky_note_2_outlined, onPressed: () {}),
      ],
    );
  }
}
