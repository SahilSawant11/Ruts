import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/bill_summary_card.dart';
import '../widgets/invoice_details_card.dart';
import '../widgets/item_details_table.dart';
import '../widgets/payment_card.dart';
import '../widgets/scan_add_item_card.dart';

/// Redesigned POS Counter Billing Screen:
/// - Connects directly below AppTopHeader with no duplicate utility bar,
///   allowing the workbench and line items table to start at the very top.
/// - Preserves the application's signature pebble-like rounded aesthetic,
///   brand purple accents (#6C5CE7), and soft ambient shadows.
/// - Left Workbench: Pebble container with 1-row metadata strip, inline scan bar,
///   and full-height line items table.
/// - Right Sidebar: Pebble summary & payment cards.
class SalesBillingScreen extends StatelessWidget {
  const SalesBillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
      child: _SalesSplitWorkspace(),
    );
  }
}

class _SalesSplitWorkspace extends StatelessWidget {
  const _SalesSplitWorkspace();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Panel (Pebble Records Workbench)
        Expanded(
          flex: 7,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundFor(context),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.borderFor(context)),
              boxShadow: AppColors.cardShadowFor(context),
            ),
            clipBehavior: Clip.antiAlias,
            child: const Column(
              children: [
                // Compact 1-row metadata strip
                InvoiceDetailsCard(compact: true),

                // Inline barcode scan row directly touching the table
                ScanAddItemCard(compact: true),

                // High-density records table: starts immediately at the top
                Expanded(child: ItemDetailsTable(expand: true)),
              ],
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // Right Sidebar (Pebble Settlement & Totals)
        const SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              children: [
                BillSummaryCard(compact: true),
                SizedBox(height: AppSpacing.sm),
                PaymentCard(compact: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
