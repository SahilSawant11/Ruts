/// Used for both POST (create — id is the new LocalItemCode) and PUT
/// (update — id is passed in the URL, this body just carries the
/// editable fields).
class SaveMaterialRequest {
  const SaveMaterialRequest({
    required this.id,
    required this.name,
    required this.category,
    required this.packing,
    required this.saleRate,
    required this.taxPercent,
  });

  final String id;
  final String name;
  final String category;
  final String packing;
  final double saleRate;
  final double taxPercent;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'packing': packing,
        'saleRate': saleRate,
        'taxPercent': taxPercent,
      };
}
