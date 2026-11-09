import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_providers.dart';
import 'models/inventory_overview_item.dart';

/// How healthy one category's stock is, for the bottle gauges.
class CategoryStock {
  const CategoryStock({
    required this.category,
    required this.products,
    required this.healthy,
    required this.low,
    required this.out,
    required this.bottles,
  });

  final String category;

  /// Products (SCM codes) in the category.
  final int products;

  /// Above their low-stock threshold.
  final int healthy;

  /// In stock but at or below the threshold.
  final int low;

  /// Zero on hand.
  final int out;

  /// Bottles on hand across the category.
  final int bottles;

  /// The gauge's fill: share of products that are healthy.
  double get fill => products == 0 ? 0 : healthy / products;

  CategoryHealth get health => fill >= 0.6
      ? CategoryHealth.good
      : fill >= 0.3
          ? CategoryHealth.watch
          : CategoryHealth.critical;
}

enum CategoryHealth { good, watch, critical }

/// Groups products by category using the same low-stock rules as the rest
/// of the Inventory screen. Biggest categories first; at most [limit].
List<CategoryStock> summarizeCategories(
  List<InventoryOverviewItem> items,
  int Function(String category, String packing) thresholdFor, {
  int limit = 8,
}) {
  final groups = <String, List<InventoryOverviewItem>>{};
  for (final i in items) {
    // Keep the name exactly as stored: the table filter matches it exactly.
    final c = i.category.trim().isEmpty ? 'Other' : i.category;
    groups.putIfAbsent(c, () => []).add(i);
  }
  final out = [
    for (final e in groups.entries)
      CategoryStock(
        category: e.key,
        products: e.value.length,
        healthy: e.value.where((i) => i.isInStockFor(thresholdFor(i.category, i.packing))).length,
        low: e.value.where((i) => i.isLowStockFor(thresholdFor(i.category, i.packing))).length,
        out: e.value.where((i) => i.isOutOfStock).length,
        bottles: e.value.fold(0, (s, i) => s + (i.qtyOnHand > 0 ? i.qtyOnHand : 0)),
      ),
  ]..sort((a, b) => b.products != a.products ? b.products.compareTo(a.products) : a.category.compareTo(b.category));
  return out.take(limit).toList();
}

final categoryStockProvider = FutureProvider<List<CategoryStock>>((ref) async {
  final items = await ref.watch(inventoryOverviewProvider.future);
  final config = ref.watch(lowStockThresholdConfigProvider);
  return summarizeCategories(items, config.getThresholdFor);
});
