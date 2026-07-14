/// Mirrors the `Material` shape returned by GET /api/materials/{barcode}.
/// Field names match the JSON exactly as EF Core/System.Text.Json will
/// camelCase them by default.
class MaterialDto {
  const MaterialDto({
    required this.id,
    required this.barcode,
    required this.name,
    required this.category,
    required this.packing,
    required this.saleRate,
    required this.taxPercent,
    required this.stockQty,
  });

  final String id;
  final String barcode;
  final String name;
  final String category;
  final String packing;
  final double saleRate;
  final double taxPercent;
  final int stockQty;

  factory MaterialDto.fromJson(Map<String, dynamic> json) {
    return MaterialDto(
      id: json['id'] as String,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      packing: json['packing'] as String,
      saleRate: (json['saleRate'] as num).toDouble(),
      taxPercent: (json['taxPercent'] as num).toDouble(),
      stockQty: json['stockQty'] as int,
    );
  }
}
