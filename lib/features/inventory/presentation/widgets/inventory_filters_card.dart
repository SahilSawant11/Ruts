import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../../masters/data/masters_providers.dart';
import '../../data/inventory_providers.dart';

class InventoryFiltersCard extends ConsumerStatefulWidget {
  const InventoryFiltersCard({super.key});

  @override
  ConsumerState<InventoryFiltersCard> createState() => _InventoryFiltersCardState();
}

class _InventoryFiltersCardState extends ConsumerState<InventoryFiltersCard> {
  final _searchController = TextEditingController();
  static const _statusOptions = ['In Stock', 'Low Stock', 'Out of Stock'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    final manufacturersAsync = ref.watch(inventoryManufacturerOptionsProvider);
    final selectedCategory = ref.watch(inventoryCategoryFilterProvider);
    final selectedManufacturer = ref.watch(inventoryManufacturerFilterProvider);
    final selectedStatus = ref.watch(inventoryStatusFilterProvider);

    final categoryItems = categoriesAsync.maybeWhen(
      data: (items) => items.map((item) => item.name).toList(),
      orElse: () => const <String>[],
    );
    final manufacturerItems = manufacturersAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <String>[],
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Filters'),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppDropdown<String>(
                  label: 'CATEGORY',
                  items: categoryItems,
                  itemLabel: (value) => value,
                  value: categoryItems.contains(selectedCategory) ? selectedCategory : null,
                  hint: categoryItems.isEmpty ? 'No categories yet' : 'All categories',
                  onChanged: (value) => ref.read(inventoryCategoryFilterProvider.notifier).state = value,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppDropdown<String>(
                  label: 'MANUFACTURER',
                  items: manufacturerItems,
                  itemLabel: (value) => value,
                  value: manufacturerItems.contains(selectedManufacturer) ? selectedManufacturer : null,
                  hint: manufacturerItems.isEmpty ? 'No manufacturers yet' : 'All manufacturers',
                  onChanged: (value) => ref.read(inventoryManufacturerFilterProvider.notifier).state = value,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppDropdown<String>(
                  label: 'STATUS',
                  items: _statusOptions,
                  itemLabel: (value) => value,
                  value: selectedStatus,
                  hint: 'All statuses',
                  onChanged: (value) => ref.read(inventoryStatusFilterProvider.notifier).state = value,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: AppTextField(
                  label: 'SEARCH ITEM',
                  hint: 'Bottle, can, barcode or name',
                  controller: _searchController,
                  onChanged: (value) => ref.read(inventorySearchFilterProvider.notifier).state = value,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SecondaryButton(
                label: 'Clear Filters',
                icon: Icons.filter_alt_off_rounded,
                onPressed: () {
                  _searchController.clear();
                  ref.read(inventoryCategoryFilterProvider.notifier).state = null;
                  ref.read(inventoryManufacturerFilterProvider.notifier).state = null;
                  ref.read(inventoryStatusFilterProvider.notifier).state = null;
                  ref.read(inventorySearchFilterProvider.notifier).state = '';
                },
              ),
              const Spacer(),
              PrimaryButton(label: 'Add Stock', icon: Icons.add_rounded, onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}
