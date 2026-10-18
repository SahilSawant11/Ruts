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
    required this.manufacturer,
    required this.category,
    required this.packing,
    required this.qtyOnHand,
    required this.reorderLevel,
    required this.saleRate,
  });

  final String materialId;
  final String barcode;
  final String name;
  final String manufacturer;
  final String category;
  final String packing;
  final int qtyOnHand;
  final int reorderLevel;

  /// Sale rate from the Material Master (₹ per unit).
  final double saleRate;

  /// Current on-hand stock value at sale rate.
  double get onHandValue => saleRate * qtyOnHand;

  bool get isOutOfStock => qtyOnHand <= 0;
  bool get isLowStock => qtyOnHand > 0 && qtyOnHand <= reorderLevel;
  bool get isAtRisk => qtyOnHand <= reorderLevel;
  bool get isInStock => qtyOnHand > reorderLevel;

  bool isLowStockFor(int threshold) => qtyOnHand > 0 && qtyOnHand <= threshold;
  bool isAtRiskFor(int threshold) => qtyOnHand <= threshold;
  bool isInStockFor(int threshold) => qtyOnHand > threshold;
}
