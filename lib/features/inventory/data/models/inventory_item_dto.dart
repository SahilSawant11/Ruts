/// Mirrors the grouped shape returned by GET /api/inventory — one row
/// per Material, qty summed across all batches.
class InventoryItemDto {
  const InventoryItemDto({
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

  factory InventoryItemDto.fromJson(Map<String, dynamic> json) {
    return InventoryItemDto(
      materialId: json['materialId'] as String,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      qtyOnHand: json['qtyOnHand'] as int,
      reorderLevel: json['reorderLevel'] as int,
    );
  }
}
