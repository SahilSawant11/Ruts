/// A single row in the Purchase Bill's Item Details table.
/// Built when the user confirms the "Add Material Line" dialog —
/// discount/tax amounts and the line total are computed here so the
/// UI and the save payload always agree with each other.
class PurchaseLineItem {
  const PurchaseLineItem({
    required this.index,
    required this.materialId,
    required this.material,
    required this.batch,
    required this.packing,
    required this.qty,
    required this.rate,
    required this.discountPercent,
    required this.taxPercent,
  });

  final int index;
  final String materialId;
  final String material;
  final String batch;
  final String packing;
  final int qty;
  final double rate;
  final double discountPercent;
  final double taxPercent;

  double get grossValue => rate * qty;
  double get discountAmount => grossValue * discountPercent / 100;
  double get taxableAmount => grossValue - discountAmount;
  double get taxAmount => taxableAmount * taxPercent / 100;
  double get amount => taxableAmount + taxAmount;

  PurchaseLineItem copyWith({int? index}) {
    return PurchaseLineItem(
      index: index ?? this.index,
      materialId: materialId,
      material: material,
      batch: batch,
      packing: packing,
      qty: qty,
      rate: rate,
      discountPercent: discountPercent,
      taxPercent: taxPercent,
    );
  }
}
