import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/purchase_line_item.dart';
import '../purchase_cart_controller.dart';
import 'add_material_line_dialog.dart';

/// High-density purchase items table: starts immediately under the quick add bar.
/// Styled in the app's pebble aesthetic: soft rounded hovers,
/// purple accent headers, and monospace number formatting.
class PurchaseItemTable extends ConsumerWidget {
  const PurchaseItemTable({super.key, this.expand = true});

  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(purchaseCartControllerProvider);
    final items = cart.items;
    final isDark = AppColors.isDark(context);

    final headerBg = isDark ? AppColors.surfaceFor(context) : AppColors.surfaceAltFor(context);
    final borderColor = AppColors.borderFor(context);

    final content = Column(
      children: [
        // Sticky Header Row
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: headerBg,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              _colHeader('#', flex: 1, alignment: Alignment.centerLeft),
              _colHeader('MAKE', flex: 3),
              _colHeader('MATERIAL / ITEM NAME', flex: 6),
              _colHeader('BATCH', flex: 2),
              _colHeader('PACK', flex: 2),
              _colHeader('QTY', flex: 2, alignment: Alignment.centerRight),
              _colHeader('RATE', flex: 2, alignment: Alignment.centerRight),
              _colHeader('DISC', flex: 2, alignment: Alignment.centerRight),
              _colHeader('TAX %', flex: 2, alignment: Alignment.centerRight),
              _colHeader('TOTAL', flex: 3, alignment: Alignment.centerRight),
              _colHeader('DEL', width: 36, alignment: Alignment.center),
            ],
          ),
        ),

        // Table Rows List (Expands full remaining height)
        Expanded(
          child: items.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  itemCount: items.length,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  separatorBuilder: (context, _) => Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.borderFor(context).withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _PurchaseTableRow(
                      index: index,
                      item: item,
                      onDelete: () => ref.read(purchaseCartControllerProvider.notifier).removeAt(index),
                    );
                  },
                ),
        ),
      ],
    );

    return content;
  }

  Widget _colHeader(
    String label, {
    int? flex,
    double? width,
    Alignment alignment = Alignment.centerLeft,
  }) {
    final child = Align(
      alignment: alignment,
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex ?? 1, child: child);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primarySoftFor(context),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No purchase lines added yet',
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Press F2 or click "Add Material Line" above to add batch stock',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: () => showAddMaterialLineDialog(context),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Add First Line (F2)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseTableRow extends StatefulWidget {
  const _PurchaseTableRow({
    required this.index,
    required this.item,
    required this.onDelete,
  });

  final int index;
  final PurchaseLineItem item;
  final VoidCallback onDelete;

  @override
  State<_PurchaseTableRow> createState() => _PurchaseTableRowState();
}

class _PurchaseTableRowState extends State<_PurchaseTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final rowBg = _isHovered ? AppColors.surfaceFor(context) : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 38,
        color: rowBg,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            // Index
            Expanded(
              flex: 1,
              child: Text(
                '${widget.index + 1}',
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ),

            // Make / Manufacturer
            Expanded(
              flex: 3,
              child: Text(
                item.manufacturer,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryFor(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Material Name
            Expanded(
              flex: 6,
              child: Text(
                item.material,
                style: AppTypography.body.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryFor(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Batch
            Expanded(
              flex: 2,
              child: Text(
                item.batch.isEmpty ? '—' : item.batch,
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondaryFor(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Packing
            Expanded(
              flex: 2,
              child: Text(
                item.packing,
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondaryFor(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Qty
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${item.qty}',
                  style: AppTypography.mono.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
              ),
            ),

            // Rate
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '₹${item.rate.toStringAsFixed(2)}',
                  style: AppTypography.mono.copyWith(
                    fontSize: 12,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
              ),
            ),

            // Discount
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  item.discountAmount > 0 ? '₹${item.discountAmount.toStringAsFixed(2)}' : '—',
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    color: item.discountAmount > 0 ? AppColors.success : AppColors.textMutedFor(context),
                  ),
                ),
              ),
            ),

            // Tax %
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${item.taxPercent.toStringAsFixed(0)}%',
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
            ),

            // Total Amount
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '₹${item.amount.toStringAsFixed(2)}',
                  style: AppTypography.mono.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
              ),
            ),

            // Delete Action
            SizedBox(
              width: 36,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  color: AppColors.danger.withValues(alpha: 0.8),
                  hoverColor: AppColors.danger.withValues(alpha: 0.1),
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Remove Line',
                  onPressed: widget.onDelete,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
