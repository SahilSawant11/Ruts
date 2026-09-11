import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/sale_line_item.dart';
import '../cart_controller.dart';

/// High-density records table: starts immediately under the scan bar.
/// Styled in the app's pebble aesthetic: soft rounded hovers,
/// purple accent hotkeys, and monospace number formatting.
class ItemDetailsTable extends ConsumerWidget {
  const ItemDetailsTable({super.key, this.expand = true});

  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final items = cart.items;
    final isDark = AppColors.isDark(context);

    final headerBg = isDark ? AppColors.surfaceFor(context) : AppColors.surfaceAltFor(context);
    final borderColor = AppColors.borderFor(context);

    return Column(
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
              _colHeader('BARCODE', flex: 3),
              _colHeader('MATERIAL / ITEM NAME', flex: 6),
              _colHeader('BATCH', flex: 2),
              _colHeader('PACK', flex: 2),
              _colHeader('QTY', flex: 2, alignment: Alignment.centerRight),
              _colHeader('RATE', flex: 2, alignment: Alignment.centerRight),
              _colHeader('TAX %', flex: 2, alignment: Alignment.centerRight),
              _colHeader('TAX AMT', flex: 2, alignment: Alignment.centerRight),
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
                    indent: AppSpacing.sm,
                    endIndent: AppSpacing.sm,
                    color: AppColors.borderFor(context).withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _TableRow(
                      key: ValueKey(item.barcode + item.index.toString()),
                      index: index,
                      item: item,
                    );
                  },
                ),
        ),

        // Hotkey Footer Strip
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceFor(context) : AppColors.surfaceFor(context),
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _hotkeyPill('F1', 'Focus Scan'),
                  _hotkeyDivider(),
                  _hotkeyPill('F4', 'Qty'),
                  _hotkeyDivider(),
                  _hotkeyPill('F8', 'Save & Print'),
                  _hotkeyDivider(),
                  _hotkeyPill('Del', 'Delete Row'),
                ],
              ),
              Text(
                '${items.length} line item${items.length == 1 ? '' : 's'} · ${cart.totalQty} total units',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _colHeader(String title, {int? flex, double? width, Alignment alignment = Alignment.centerLeft}) {
    return Builder(
      builder: (context) {
        final text = Align(
          alignment: alignment,
          child: Text(
            title,
            style: AppTypography.label.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textMutedFor(context),
            ),
          ),
        );

        if (width != null) {
          return SizedBox(width: width, child: text);
        }
        return Expanded(flex: flex ?? 1, child: text);
      },
    );
  }

  Widget _hotkeyPill(String keyLabel, String actionLabel) {
    return Builder(
      builder: (context) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primarySoftFor(context),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                keyLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontFamily: AppTypography.mono.fontFamily,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              actionLabel,
              style: AppTypography.caption.copyWith(
                fontSize: 10.5,
                color: AppColors.textSecondaryFor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _hotkeyDivider() {
    return Builder(
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '·',
            style: TextStyle(
              color: AppColors.textMutedFor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoftFor(context),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ready for scanning',
            style: AppTypography.h2.copyWith(
              fontSize: 14,
              color: AppColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scan barcode with scanner gun or type item code above (F1)',
            style: AppTypography.bodyMuted.copyWith(
              fontSize: 12,
              color: AppColors.textSecondaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends ConsumerStatefulWidget {
  const _TableRow({
    super.key,
    required this.index,
    required this.item,
  });

  final int index;
  final SaleLineItem item;

  @override
  ConsumerState<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends ConsumerState<_TableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    final rowBg = _isHovered
        ? AppColors.primarySoftFor(context)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: rowBg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            // #
            _cell(
              '${item.index}',
              flex: 1,
              alignment: Alignment.centerLeft,
              textStyle: AppTypography.caption.copyWith(color: AppColors.textMutedFor(context)),
            ),

            // Barcode
            _cell(
              item.barcode,
              flex: 3,
              alignment: Alignment.centerLeft,
              textStyle: AppTypography.mono.copyWith(
                fontSize: 11.5,
                color: AppColors.textSecondaryFor(context),
              ),
            ),

            // Material / Item Name
            Expanded(
              flex: 6,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.material,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
              ),
            ),

            // Batch
            _cell(
              item.batch,
              flex: 2,
              alignment: Alignment.centerLeft,
              textStyle: AppTypography.mono.copyWith(fontSize: 11, color: AppColors.textSecondaryFor(context)),
            ),

            // Pack
            _cell(
              item.pack,
              flex: 2,
              alignment: Alignment.centerLeft,
              textStyle: AppTypography.bodyMuted.copyWith(fontSize: 11, color: AppColors.textSecondaryFor(context)),
            ),

            // Qty (Interactive pebble adjustment)
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isHovered)
                      InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: () {
                          if (item.qty > 1) {
                            ref.read(cartControllerProvider.notifier).updateQty(widget.index, item.qty - 1);
                          } else {
                            ref.read(cartControllerProvider.notifier).removeAt(widget.index);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundFor(context),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.remove_rounded, size: 12, color: AppColors.primary),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '${item.qty}',
                        style: AppTypography.mono.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryFor(context),
                        ),
                      ),
                    ),
                    if (_isHovered)
                      InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: () {
                          ref.read(cartControllerProvider.notifier).updateQty(widget.index, item.qty + 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundFor(context),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded, size: 12, color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Rate
            _cell(
              item.rate.toStringAsFixed(2),
              flex: 2,
              alignment: Alignment.centerRight,
              textStyle: AppTypography.mono.copyWith(
                fontSize: 11.5,
                color: AppColors.textPrimaryFor(context),
              ),
            ),

            // Tax %
            _cell(
              '${item.taxPercent.toStringAsFixed(0)}%',
              flex: 2,
              alignment: Alignment.centerRight,
              textStyle: AppTypography.mono.copyWith(fontSize: 11, color: AppColors.textMutedFor(context)),
            ),

            // Tax Amt
            _cell(
              item.taxAmount.toStringAsFixed(2),
              flex: 2,
              alignment: Alignment.centerRight,
              textStyle: AppTypography.mono.copyWith(fontSize: 11, color: AppColors.textMutedFor(context)),
            ),

            // Total
            _cell(
              item.amount.toStringAsFixed(2),
              flex: 3,
              alignment: Alignment.centerRight,
              textStyle: AppTypography.mono.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryFor(context),
              ),
            ),

            // Del Action
            SizedBox(
              width: 36,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  color: _isHovered ? AppColors.danger : AppColors.textMutedFor(context),
                  tooltip: 'Remove line',
                  onPressed: () {
                    ref.read(cartControllerProvider.notifier).removeAt(widget.index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, {required int flex, required Alignment alignment, required TextStyle textStyle}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
      ),
    );
  }
}
