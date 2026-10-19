import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../../masters/data/masters_providers.dart';
import '../../data/inventory_providers.dart';
import '../../data/models/inventory_overview_item.dart';

/// Full-width inventory data table adhering strictly to the Ruts design system.
///
/// Features:
///  - Prominent, comfortable search bar with fixed-width compact filter dropdowns
///  - Sticky/frozen table header: Columns remain visible as rows scroll
///  - Clean, separate columns for ON HAND (count only) and STATUS (status badge only)
///  - SCM Code prominently labeled per enterprise requirements
///  - Threshold-aware stock health status
class LiveStockTable extends ConsumerStatefulWidget {
  const LiveStockTable({super.key});

  @override
  ConsumerState<LiveStockTable> createState() => _LiveStockTableState();
}

class _LiveStockTableState extends ConsumerState<LiveStockTable> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    _searchController.clear();
    ref.read(inventoryCategoryFilterProvider.notifier).state = null;
    ref.read(inventoryManufacturerFilterProvider.notifier).state = null;
    ref.read(inventoryStatusFilterProvider.notifier).state = null;
    ref.read(inventoryLowStockPinProvider.notifier).state = false;
    ref.read(inventorySearchFilterProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(filteredInventoryOverviewProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final manufacturersAsync = ref.watch(inventoryManufacturerOptionsProvider);
    final selectedCategory = ref.watch(inventoryCategoryFilterProvider);
    final selectedManufacturer = ref.watch(inventoryManufacturerFilterProvider);
    final selectedStatus = ref.watch(inventoryStatusFilterProvider);
    final lowStockPinned = ref.watch(inventoryLowStockPinProvider);
    final thresholdConfig = ref.watch(lowStockThresholdConfigProvider);
    final lowStockThreshold = thresholdConfig.defaultThreshold;

    final categoryItems = categoriesAsync.maybeWhen(
      data: (items) => items.map((i) => i.name).toList(),
      orElse: () => <String>[],
    );
    final manufacturerItems = manufacturersAsync.maybeWhen(
      data: (items) => items,
      orElse: () => <String>[],
    );

    final hasActiveFilters = selectedCategory != null ||
        selectedManufacturer != null ||
        selectedStatus != null ||
        lowStockPinned ||
        _searchController.text.trim().isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Toolbar: Generous Search Bar + Fixed Filter Selectors ──
          _buildToolbar(
            context,
            categoryItems: categoryItems,
            selectedCategory: selectedCategory,
            manufacturerItems: manufacturerItems,
            selectedManufacturer: selectedManufacturer,
            selectedStatus: selectedStatus,
            lowStockPinned: lowStockPinned,
            hasActiveFilters: hasActiveFilters,
          ),

          if (lowStockPinned) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildLowStockFilterBanner(context, lowStockThreshold),
          ],

          const SizedBox(height: AppSpacing.md),

          // ── Sticky Header: Distinct Columns ────────────────────────
          _headerRow(context),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderFor(context),
          ),

          // ── Scrollable Body with Frozen Header ─────────────────────
          Expanded(
            child: inventoryAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Could not load inventory: $e',
                  style: AppTypography.bodyMuted,
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return _emptyState(context, lowStockPinned, hasActiveFilters);
                }

                // Sort: Out of stock (0) first, then low stock (1), then in stock (2)
                final sorted = [...items]
                  ..sort((a, b) {
                    final ar = a.isOutOfStock
                        ? 0
                        : (a.isAtRiskFor(thresholdConfig.getThresholdFor(a.category, a.packing)) ? 1 : 2);
                    final br = b.isOutOfStock
                        ? 0
                        : (b.isAtRiskFor(thresholdConfig.getThresholdFor(b.category, b.packing)) ? 1 : 2);
                    final rc = ar.compareTo(br);
                    return rc != 0 ? rc : a.qtyOnHand.compareTo(b.qtyOnHand);
                  });

                return ListView.separated(
                  itemCount: sorted.length,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.borderFor(context),
                  ),
                  itemBuilder: (context, index) {
                    final item = sorted[index];
                    return _dataRow(
                      context,
                      item,
                      lowStockThreshold: thresholdConfig.getThresholdFor(item.category, item.packing),
                    );
                  },
                );
              },
            ),
          ),

          // ── Footer ─────────────────────────────────────────────────
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderFor(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          inventoryAsync.maybeWhen(
            data: (items) {
              final totalValue =
                  items.fold<double>(0, (s, i) => s + i.onHandValue);
              final lowStockCount =
                  items.where((i) => i.isAtRiskFor(thresholdConfig.getThresholdFor(i.category, i.packing))).length;
              return _footer(context, items.length, totalValue, lowStockCount,
                  lowStockThreshold);
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ── Toolbar ──────────────────────────────────────────────────────────────

  Widget _buildToolbar(
    BuildContext context, {
    required List<String> categoryItems,
    required String? selectedCategory,
    required List<String> manufacturerItems,
    required String? selectedManufacturer,
    required String? selectedStatus,
    required bool lowStockPinned,
    required bool hasActiveFilters,
  }) {
    final isDark = AppColors.isDark(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Search Bar — Clean 300px fixed width, single border, no inner outline
        SizedBox(
          width: 300,
          height: 40,
          child: TextField(
            controller: _searchController,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimaryFor(context),
              fontSize: 13,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search material, SCM code…',
              hintStyle: AppTypography.body.copyWith(
                color: AppColors.textMutedFor(context),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.textMutedFor(context),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 36, minHeight: 40),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: AppColors.textMutedFor(context),
                      splashRadius: 16,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        ref.read(inventorySearchFilterProvider.notifier).state =
                            '';
                      },
                    )
                  : null,
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 36, minHeight: 40),
              filled: true,
              fillColor: AppColors.surfaceFor(context),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: AppColors.borderFor(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: AppColors.borderFor(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.3),
              ),
            ),
            onChanged: (val) {
              setState(() {});
              ref.read(inventorySearchFilterProvider.notifier).state = val;
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // 2. Category Dropdown
        SizedBox(
          width: 170,
          child: _FilterDropdown<String>(
            hint: 'All Categories',
            value: categoryItems.contains(selectedCategory)
                ? selectedCategory
                : null,
            items: categoryItems,
            itemLabel: (v) => v,
            icon: Icons.category_outlined,
            onChanged: (val) {
              ref.read(inventoryCategoryFilterProvider.notifier).state = val;
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // 3. Brand Dropdown
        SizedBox(
          width: 160,
          child: _FilterDropdown<String>(
            hint: 'All Brands',
            value: manufacturerItems.contains(selectedManufacturer)
                ? selectedManufacturer
                : null,
            items: manufacturerItems,
            itemLabel: (v) => v,
            icon: Icons.storefront_outlined,
            onChanged: (val) {
              ref.read(inventoryManufacturerFilterProvider.notifier).state =
                  val;
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // 4. Status Filter Dropdown
        SizedBox(
          width: 150,
          child: _FilterDropdown<String>(
            hint: lowStockPinned ? 'Low Stock' : 'All Stock',
            value: lowStockPinned ? null : selectedStatus,
            items: const ['In Stock', 'Low Stock', 'Out of Stock'],
            itemLabel: (v) => v,
            icon: Icons.tune_rounded,
            highlightActive: lowStockPinned || selectedStatus != null,
            onChanged: (val) {
              if (lowStockPinned) {
                ref.read(inventoryLowStockPinProvider.notifier).state = false;
              }
              ref.read(inventoryStatusFilterProvider.notifier).state = val;
            },
          ),
        ),

        // 5. Clear Filters Button
        if (hasActiveFilters) ...[
          const SizedBox(width: AppSpacing.sm),
          Tooltip(
            message: 'Reset all filters',
            child: Material(
              color: isDark
                  ? AppColors.danger.withValues(alpha: 0.15)
                  : AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: InkWell(
                onTap: _clearAllFilters,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.filter_alt_off_rounded,
                    size: 18,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),
          ),
        ],
        const Spacer(),
        Tooltip(
          message: 'Refresh stock data',
          child: Material(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.surfaceAltFor(context),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: InkWell(
              onTap: () {
                ref.invalidate(inventoryOverviewProvider);
                ref.invalidate(filteredInventoryOverviewProvider);
                ref.invalidate(inventoryListProvider);
              },
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Active Low Stock Banner ──────────────────────────────────────────────

  Widget _buildLowStockFilterBanner(
      BuildContext context, int threshold) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? AppColors.warning.withValues(alpha: 0.15)
            : AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing Low Stock items requiring reorder (on hand ≤ $threshold units).',
              style: AppTypography.body.copyWith(
                color: AppColors.warning,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              ref.read(inventoryLowStockPinProvider.notifier).state = false;
            },
            borderRadius: BorderRadius.circular(99),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Clear filter',
                    style: AppTypography.label.copyWith(
                      color: AppColors.warning,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sticky Header Row (One Thing Per Column) ─────────────────────────────

  Widget _headerRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          _hCell(context, 'PRODUCT / SCM CODE', flex: 4),
          _hCell(context, 'BRAND & CATEGORY', flex: 3),
          _hCell(context, 'VARIANT', flex: 1),
          _hCell(context, 'SELLING PRICE', flex: 2, alignEnd: true),
          _hCell(context, 'ON HAND', flex: 1, alignEnd: true),
          _hCell(context, 'STATUS', flex: 2, alignEnd: true),
          _hCell(context, 'ON HAND VALUE', flex: 2, alignEnd: true),
        ],
      ),
    );
  }

  // ── Data Row ─────────────────────────────────────────────────────────────

  Widget _dataRow(BuildContext context, InventoryOverviewItem item,
      {required int lowStockThreshold}) {
    final priceText = '₹ ${item.saleRate.toStringAsFixed(2)}';
    final valueText = '₹ ${_formatCurrency(item.onHandValue)}';
    final isOutOfStock = item.isOutOfStock;
    final isLowStock = !isOutOfStock && item.isAtRiskFor(lowStockThreshold);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Material Name & SCM Code
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAltFor(context),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.borderFor(context),
                        ),
                      ),
                      child: Text(
                        'SCM: ${item.materialId}',
                        style: AppTypography.mono.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryFor(context),
                        ),
                      ),
                    ),
                    if (item.barcode.isNotEmpty &&
                        item.barcode != item.materialId) ...[
                      const SizedBox(width: 6),
                      Text(
                        item.barcode,
                        style: AppTypography.mono.copyWith(
                          fontSize: 10.5,
                          color: AppColors.textMutedFor(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // 2. Brand & Category
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.manufacturer.isEmpty ? '—' : item.manufacturer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),

          // 3. Variant
          Expanded(
            flex: 1,
            child: Text(
              item.packing.isEmpty ? '—' : item.packing,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
          ),

          // 4. Selling Price
          Expanded(
            flex: 2,
            child: Text(
              priceText,
              textAlign: TextAlign.end,
              style: AppTypography.mono.copyWith(
                fontSize: 13,
                color: AppColors.textPrimaryFor(context),
              ),
            ),
          ),

          // 5. On Hand: ONLY the stock count number
          Expanded(
            flex: 1,
            child: Text(
              '${item.qtyOnHand}',
              textAlign: TextAlign.end,
              style: AppTypography.mono.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isOutOfStock
                    ? AppColors.danger
                    : isLowStock
                        ? AppColors.warning
                        : AppColors.textPrimaryFor(context),
              ),
            ),
          ),

          // 6. Status: ONLY the status badge (no count text)
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: _PureStatusBadge(
                isOutOfStock: isOutOfStock,
                isLowStock: isLowStock,
              ),
            ),
          ),

          // 7. On Hand Value
          Expanded(
            flex: 2,
            child: Text(
              valueText,
              textAlign: TextAlign.end,
              style: AppTypography.mono.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryFor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────

  Widget _emptyState(
      BuildContext context, bool lowStockPinned, bool hasFilters) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              lowStockPinned
                  ? Icons.check_circle_outline_rounded
                  : Icons.search_off_rounded,
              size: 26,
              color: lowStockPinned
                  ? AppColors.success
                  : AppColors.textMutedFor(context),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            lowStockPinned
                ? 'All inventory items are healthy'
                : hasFilters
                    ? 'No matching materials found'
                    : 'No inventory items cataloged',
            style: AppTypography.sectionTitle.copyWith(
              color: AppColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lowStockPinned
                ? 'All items currently in stock have quantities above their low stock threshold.'
                : 'Try adjusting your search query or reset your filters.',
            style: AppTypography.bodyMuted.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────

  Widget _footer(BuildContext context, int count, double totalValue,
      int lowStockCount, int threshold) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text(
            '$count material${count == 1 ? '' : 's'} displayed',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
          if (lowStockCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.isDark(context)
                    ? AppColors.warning.withValues(alpha: 0.15)
                    : AppColors.warningSoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '$lowStockCount low stock (≤ $threshold)',
                style: AppTypography.caption.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            'Total Valuation: ₹ ${_formatCurrency(totalValue)}',
            style: AppTypography.mono.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: AppColors.textPrimaryFor(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _hCell(BuildContext context, String text,
      {required int flex, bool alignEnd = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.label.copyWith(
          color: AppColors.textMutedFor(context),
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  static String _formatCurrency(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)} L';
    if (v >= 1000) {
      final s = v.toInt().toString();
      final last3 = s.substring(s.length - 3);
      final rest = s.substring(0, s.length - 3);
      final buf = StringBuffer();
      for (var i = 0; i < rest.length; i++) {
        if (i != 0 && (rest.length - i) % 2 == 0) buf.write(',');
        buf.write(rest[i]);
      }
      return '${buf.toString()},$last3';
    }
    return v.toStringAsFixed(0);
  }
}

// ── Compact Filter Dropdown ──────────────────────────────────────────────────

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.items,
    required this.itemLabel,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.value,
    this.highlightActive = false,
  });

  final List<T> items;
  final String Function(T) itemLabel;
  final String hint;
  final IconData icon;
  final T? value;
  final ValueChanged<T?> onChanged;
  final bool highlightActive;

  @override
  Widget build(BuildContext context) {
    final isActive = value != null || highlightActive;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.borderFor(context),
          width: isActive ? 1.2 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: AppColors.surfaceFor(context),
          hint: Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive
                    ? AppColors.primary
                    : AppColors.textMutedFor(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textMutedFor(context),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.textMutedFor(context),
          ),
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimaryFor(context),
            fontSize: 13,
          ),
          items: [
            if (value != null)
              DropdownMenuItem<T>(
                value: null,
                child: Text(
                  'Clear selection',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
            ...items.map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item)),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Pure Status Badge (Shows ONLY the Status Pill) ───────────────────────────

class _PureStatusBadge extends StatelessWidget {
  const _PureStatusBadge({
    required this.isOutOfStock,
    required this.isLowStock,
  });

  final bool isOutOfStock;
  final bool isLowStock;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    if (isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.danger.withValues(alpha: 0.16)
              : AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Out of Stock',
              style: AppTypography.label.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      );
    }

    if (isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.warning.withValues(alpha: 0.16)
              : AppColors.warningSoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 12,
              color: AppColors.warning,
            ),
            const SizedBox(width: 4),
            Text(
              'Low Stock',
              style: AppTypography.label.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      );
    }

    // In Stock
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.success.withValues(alpha: 0.14)
            : AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'In Stock',
            style: AppTypography.label.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
