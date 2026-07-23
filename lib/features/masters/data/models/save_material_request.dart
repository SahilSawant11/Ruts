/// Used for both POST (create — id is the new LocalItemCode) and PUT
/// (update — id is passed in the URL, this body just carries the
/// editable fields).
class SaveMaterialRequest {
  const SaveMaterialRequest({
    required this.id,
    this.barcode,
    required this.name,
    required this.category,
    required this.packing,
    required this.saleRate,
    required this.taxPercent,
  });

  final String id;

  /// The real scannable barcode, if this item has one — distinct from
  /// [id] (the internal Local Item Code). Left blank, the server falls
  /// back to using the item code as the barcode too.
  final String? barcode;
  final String name;
  final String category;
  final String packing;
  final double saleRate;
  final double taxPercent;

  Map<String, dynamic> toJson() => {
        'id': id,
        'barcode': barcode,
        'name': name,
        'category': category,
        'packing': packing,
        'saleRate': saleRate,
        'taxPercent': taxPercent,
      };
}
