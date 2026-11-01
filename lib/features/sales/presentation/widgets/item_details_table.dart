import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/sale_line_item.dart';
import '../cart_controller.dart';
import '../../../../core/format/money.dart';

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

    // Below ~760px (Windows laptops at 125% scaling) drop the Barcode,
    // Batch and Tax Amt columns so amounts never wrap; the barcode moves
    // under the item name.
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 760;
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
                if (!compact) _colHeader('BARCODE', flex: 3),
                _colHeader('MATERIAL / ITEM NAME', flex: 6),
                if (!compact) _colHeader('BATCH', flex: 2),
                _colHeader('PACK', flex: 2),
                _colHeader('QTY', flex: 2, alignment: Alignment.centerRight),
                _colHeader('RATE', flex: 2, alignment: Alignment.centerRight),
                _colHeader('TAX %', flex: 2, alignment: Alignment.centerRight),
                if (!compact) _colHeader('TAX AMT', flex: 2, alignment: Alignment.centerRight),
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
                        compact: compact,
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
                const SizedBox.shrink(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: cart.isLimitReached
                            ? AppColors.danger.withValues(alpha: 0.12)
                            : AppColors.primarySoftFor(context),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: cart.isLimitReached
                              ? AppColors.danger.withValues(alpha: 0.35)
                              : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(
                            AppIcons.liquorBottle,
                            size: 13,
                            color: cart.isLimitReached ? AppColors.danger : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${cart.totalQty} / ${CartController.maxBottlesLimit} bottles',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cart.isLimitReached ? AppColors.danger : AppColors.primary,
                              fontFamily: AppTypography.mono.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${items.length} row${items.length == 1 ? '' : 's'}',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
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
            child: const AppIcon(
              AppIcons.barcode,
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
            'Scan barcode with scanner gun or type SCM code above (F1)',
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
    this.compact = false,
  });

  final bool compact;

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
    final rowBg = _isHovered ? AppColors.primarySoftFor(context) : Colors.transparent;

    return Tooltip(
      message: 'Double-click to edit in scan bar',
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onDoubleTap: () {
          ref.read(cartControllerProvider.notifier).removeAt(widget.index);
          ref.read(salesEditingLineProvider.notifier).state = item;
        },
        child: MouseRegion(
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
                if (!widget.compact)
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.material,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryFor(context),
                              ),
                            ),
                            if (widget.compact)
                              Text(
                                item.barcode,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    AppTypography.mono.copyWith(fontSize: 9.5, color: AppColors.textMutedFor(context)),
                              ),
                          ],
                        ),
                      ),
                      if (_isHovered)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoftFor(context),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Double-click to edit',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Batch
                if (!widget.compact)
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

                // Qty
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
                              child: const AppIcon(AppIcons.remove, size: 12, color: AppColors.primary),
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
                              child: const AppIcon(AppIcons.add, size: 12, color: AppColors.primary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Rate
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Money.plain(item.rate),
                        maxLines: 1,
                        style: AppTypography.mono.copyWith(
                          fontSize: 11.5,
                          color: AppColors.textPrimaryFor(context),
                        ),
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
                      style: AppTypography.mono.copyWith(fontSize: 11, color: AppColors.textMutedFor(context)),
                    ),
                  ),
                ),

                // Tax Amt
                if (!widget.compact)
                  _cell(
                    Money.plain(item.taxAmount),
                    flex: 2,
                    alignment: Alignment.centerRight,
                    textStyle: AppTypography.mono.copyWith(fontSize: 11, color: AppColors.textMutedFor(context)),
                  ),

                // Total
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Money.plain(item.amount),
                        style: AppTypography.mono.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryFor(context),
                        ),
                      ),
                    ),
                  ),
                ),

                // Actions: Del
                SizedBox(
                  width: 36,
                  child: Center(
                    child: IconButton(
                      icon: const AppIcon(AppIcons.close, size: 16),
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
