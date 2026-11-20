/// A single row in the Purchase Bill's Item Details table.
/// Built when the user confirms the "Add Material Line" dialog —
/// discount/tax amounts and the line total are computed here so the
/// UI and the save payload always agree with each other.
class PurchaseLineItem {
  const PurchaseLineItem({
    required this.index,
    required this.materialId,
    required this.manufacturer,
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
  final String manufacturer;
  final String material;
  final String batch;
  final String packing;
  final int qty;
  final double rate;
  final double discountPercent;
  final double taxPercent;

  // Every money figure is kept in whole paise, so the line, the bill and
  // the supplier's account always agree to the paisa.
  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  double get grossValue => _round2(rate * qty);
  double get discountAmount => _round2(grossValue * discountPercent / 100);
  double get taxableAmount => _round2(grossValue - discountAmount);
  double get taxAmount => _round2(taxableAmount * taxPercent / 100);
  double get amount => _round2(taxableAmount + taxAmount);

  PurchaseLineItem copyWith({
    int? index,
    String? materialId,
    String? manufacturer,
    String? material,
    String? batch,
    String? packing,
    int? qty,
    double? rate,
    double? discountPercent,
    double? taxPercent,
  }) {
    return PurchaseLineItem(
      index: index ?? this.index,
      materialId: materialId ?? this.materialId,
      manufacturer: manufacturer ?? this.manufacturer,
      material: material ?? this.material,
      batch: batch ?? this.batch,
      packing: packing ?? this.packing,
      qty: qty ?? this.qty,
      rate: rate ?? this.rate,
      discountPercent: discountPercent ?? this.discountPercent,
      taxPercent: taxPercent ?? this.taxPercent,
    );
  }
}
