/// Used for both POST (create — id is the new LocalItemCode) and PUT
/// (update — id is passed in the URL, this body just carries the
/// editable fields).
class SaveMaterialRequest {
  const SaveMaterialRequest({
    required this.id,
    this.barcode,
    required this.name,
    required this.manufacturer,
    required this.category,
    required this.packing,
    required this.saleRate,
    required this.taxPercent,
    this.isActive = true,
    this.scmCode,
    this.liquorType = '',
    this.counterBrandName = '',
    this.wholesaleRate = 0,
    this.discountPercent = 0,
    this.defaultSupplierId = '',
  });

  /// Supplier id that pre-fills Purchase; empty = none.
  final String defaultSupplierId;

  /// SCM code; null = same as [id]. Differs from [id] when another
  /// material already uses this SCM code with a different barcode.
  final String? scmCode;
  final String liquorType;
  /// Counter brand the item rolls up into. Blank → the display name.
  final String counterBrandName;
  final double wholesaleRate;
  final double discountPercent;

  final String id;

  /// The real scannable barcode, if this item has one — distinct from
  /// [id] (the internal SCM Code). Left blank, the server falls
  /// back to using the item code as the barcode too.
  final String? barcode;
  final String name;
  final String manufacturer;
  final String category;
  final String packing;
  final double saleRate;
  final double taxPercent;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'id': id,
        'barcode': barcode,
        'name': name,
        'manufacturer': manufacturer,
        'category': category,
        'packing': packing,
        'saleRate': saleRate,
        'taxPercent': taxPercent,
        'isActive': isActive,
        'scmCode': scmCode ?? id,
        'liquorType': liquorType,
        'counterBrandName': counterBrandName,
        'wholesaleRate': wholesaleRate,
        'discountPercent': discountPercent,
        'defaultSupplierId': defaultSupplierId,
      };
}
