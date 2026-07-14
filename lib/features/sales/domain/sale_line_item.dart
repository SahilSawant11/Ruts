import '../data/models/material_dto.dart';

/// A single row in the Item Details table / the active cart.
/// Built from a scanned [MaterialDto] once the barcode lookup succeeds;
/// `amount`/`taxAmount` are computed here so the UI never has to.
class SaleLineItem {
  const SaleLineItem({
    required this.index,
    required this.barcode,
    required this.type,
    required this.material,
    required this.batch,
    required this.pack,
    required this.qty,
    required this.rate,
    required this.discountPercent,
    required this.taxPercent,
  });

  final int index;
  final String barcode;
  final String type;
  final String material;
  final String batch;
  final String pack;
  final int qty;
  final double rate;
  final double discountPercent;
  final double taxPercent;

  double get grossValue => rate * qty;
  double get discountAmount => grossValue * discountPercent / 100;
  double get taxableAmount => grossValue - discountAmount;
  double get taxAmount => taxableAmount * taxPercent / 100;
  double get amount => taxableAmount + taxAmount;

  /// Builds a new cart row from a freshly scanned material. `type` uses
  /// the material's category as a stand-in for the license/item-type
  /// column shown on screen (e.g. "Lic") until Material Master exposes
  /// a dedicated type field.
  factory SaleLineItem.fromMaterial(
    MaterialDto material, {
    required int index,
    int qty = 1,
    String batch = '-',
  }) {
    return SaleLineItem(
      index: index,
      barcode: material.barcode,
      type: material.category,
      material: material.name,
      batch: batch,
      pack: material.packing,
      qty: qty,
      rate: material.saleRate,
      discountPercent: 0,
      taxPercent: material.taxPercent,
    );
  }

  SaleLineItem copyWith({int? index, int? qty}) {
    return SaleLineItem(
      index: index ?? this.index,
      barcode: barcode,
      type: type,
      material: material,
      batch: batch,
      pack: pack,
      qty: qty ?? this.qty,
      rate: rate,
      discountPercent: discountPercent,
      taxPercent: taxPercent,
    );
  }
}
