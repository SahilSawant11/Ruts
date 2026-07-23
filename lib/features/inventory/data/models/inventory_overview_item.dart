/// One row per material in the FULL catalog (not just ones that have
/// been purchased) — merges Material Master's material list with
/// GET /api/inventory's stock levels. A material with no purchase
/// history yet still shows up here as qtyOnHand: 0 / Out of Stock,
/// instead of being silently absent (which is what GET /api/inventory
/// alone would do, since it only returns materials with a stock row).
class InventoryOverviewItem {
  const InventoryOverviewItem({
    required this.materialId,
    required this.barcode,
    required this.name,
    required this.category,
    required this.qtyOnHand,
    required this.reorderLevel,
  });

  final String materialId;
  final String barcode;
  final String name;
  final String category;
  final int qtyOnHand;
  final int reorderLevel;

  bool get isOutOfStock => qtyOnHand <= 0;
  bool get isLowStock => !isOutOfStock && qtyOnHand <= reorderLevel;
  bool get isInStock => !isOutOfStock && !isLowStock;
}
