/// Mirrors the `Material` shape returned by GET /api/materials/{barcode}.
/// Field names match the JSON exactly as EF Core/System.Text.Json will
/// camelCase them by default.
class MaterialDto {
  const MaterialDto({
    required this.id,
    required this.barcode,
    required this.name,
    required this.manufacturer,
    required this.category,
    required this.packing,
    required this.saleRate,
    required this.taxPercent,
    required this.stockQty,
    this.isActive = true,
    this.isPendingSync = false,
    String? scmCode,
    this.liquorType = '',
    this.counterBrandName = '',
    this.counterBrandId = '',
    this.wholesaleRate = 0,
    this.discountPercent = 0,
    this.defaultSupplierId = '',
  }) : scmCode = scmCode ?? id;

  final String id;
  final String barcode;
  final String name;
  final String manufacturer;
  final String category;
  final String packing;
  final double saleRate;
  final double taxPercent;
  final int stockQty;
  final bool isActive;
  final bool isPendingSync;

  /// The SCM code (not unique — see `CachedMaterials.scmCode`).
  final String scmCode;
  /// Beer type: Mild / Strong / Fermented; empty otherwise.
  final String liquorType;
  final String counterBrandName;
  final String counterBrandId;
  final double wholesaleRate;
  final double discountPercent;
  /// Supplier this item usually comes from (empty = none).
  final String defaultSupplierId;

  factory MaterialDto.fromJson(Map<String, dynamic> json) {
    return MaterialDto(
      id: json['id'] as String,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      manufacturer: (json['manufacturer'] as String?) ?? '',
      category: json['category'] as String,
      packing: (json['packing'] as String?) ?? '',
      saleRate: (json['saleRate'] as num).toDouble(),
      taxPercent: (json['taxPercent'] as num).toDouble(),
      stockQty: json['stockQty'] as int,
      isActive: (json['isActive'] as bool?) ?? true,
      isPendingSync: false,
      scmCode: json['scmCode'] as String?,
      liquorType: (json['liquorType'] as String?) ?? '',
      counterBrandName: (json['counterBrandName'] as String?) ?? '',
      counterBrandId: (json['counterBrandId'] as String?) ?? '',
      wholesaleRate: (json['wholesaleRate'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      defaultSupplierId: (json['defaultSupplierId'] as String?) ?? '',
    );
  }

  MaterialDto copyWith({
    String? id,
    String? barcode,
    String? name,
    String? manufacturer,
    String? category,
    String? packing,
    double? saleRate,
    double? taxPercent,
    int? stockQty,
    bool? isActive,
    bool? isPendingSync,
    String? scmCode,
    String? liquorType,
    String? counterBrandName,
    String? counterBrandId,
    double? wholesaleRate,
    double? discountPercent,
    String? defaultSupplierId,
  }) {
    return MaterialDto(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      category: category ?? this.category,
      packing: packing ?? this.packing,
      saleRate: saleRate ?? this.saleRate,
      taxPercent: taxPercent ?? this.taxPercent,
      stockQty: stockQty ?? this.stockQty,
      isActive: isActive ?? this.isActive,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      scmCode: scmCode ?? this.scmCode,
      liquorType: liquorType ?? this.liquorType,
      counterBrandName: counterBrandName ?? this.counterBrandName,
      counterBrandId: counterBrandId ?? this.counterBrandId,
      wholesaleRate: wholesaleRate ?? this.wholesaleRate,
      discountPercent: discountPercent ?? this.discountPercent,
      defaultSupplierId: defaultSupplierId ?? this.defaultSupplierId,
    );
  }
}
