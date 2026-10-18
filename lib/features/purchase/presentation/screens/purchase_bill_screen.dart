import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/add_material_line_dialog.dart';
import '../widgets/bill_details_card.dart';
import '../widgets/extra_charges_totals_card.dart';
import '../widgets/purchase_item_table.dart';
import '../widgets/purchase_quick_add_bar.dart';
import '../widgets/purchase_summary_card.dart';

/// Redesigned POS Inward / Purchase Screen:
/// - Aligned to match the visual architecture and UX of SalesBillingScreen.
/// - Connects directly below AppTopHeader with no duplicate utility bar,
///   allowing the inward workbench and records table to start at the very top.
/// - Preserves the application's signature pebble-like rounded aesthetic,
///   brand purple accents (#6C5CE7), and soft ambient shadows.
/// - Left Workbench: Pebble container with 1-row metadata strip, inline quick-add bar,
///   and full-height high-density line items table.
/// - Right Sidebar: Pebble summary & settlement cards with F8 save capability.
class PurchaseBillScreen extends StatefulWidget {
  const PurchaseBillScreen({super.key});

  @override
  State<PurchaseBillScreen> createState() => _PurchaseBillScreenState();
}

class _PurchaseBillScreenState extends State<PurchaseBillScreen> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final isF2 = event.logicalKey == LogicalKeyboardKey.f2 || event.physicalKey == PhysicalKeyboardKey.f2;
    if (isF2) {
      showAddMaterialLineDialog(context);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
      child: _PurchaseSplitWorkspace(),
    );
  }
}

class _PurchaseSplitWorkspace extends StatelessWidget {
  const _PurchaseSplitWorkspace();

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
                // Compact 1-row inward metadata strip
                BillDetailsCard(compact: true),

                // Inline quick add bar directly touching the table
                PurchaseQuickAddBar(),

                // High-density records table: expands full remaining height
                Expanded(child: PurchaseItemTable(expand: true)),
              ],
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // Right Sidebar (Pebble Summary & Settlement)
        const SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              children: [
                PurchaseSummaryCard(compact: true),
                SizedBox(height: AppSpacing.sm),
                ExtraChargesTotalsCard(compact: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
