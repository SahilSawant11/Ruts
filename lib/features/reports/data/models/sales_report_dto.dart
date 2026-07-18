/// A single aggregated row — one per material across the queried
/// date range, matching the client's real DailySaleReport export
/// (Local Item Code / Brand Name / Size / Qty Case / Qty Loose).
class SalesReportItemDto {
  const SalesReportItemDto({
    required this.materialId,
    required this.materialName,
    required this.packing,
    required this.qtyCase,
    required this.qtyLoose,
    required this.amount,
  });

  final String materialId;
  final String materialName;
  final String? packing;
  final int qtyCase;
  final int qtyLoose;
  final double amount;

  factory SalesReportItemDto.fromJson(Map<String, dynamic> json) {
    return SalesReportItemDto(
      materialId: json['materialId'] as String,
      materialName: json['materialName'] as String,
      packing: json['packing'] as String?,
      qtyCase: json['qtyCase'] as int,
      qtyLoose: json['qtyLoose'] as int,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

/// The full GET /api/reports/sales response: summary figures +
/// the aggregated item rows.
class SalesReportDto {
  const SalesReportDto({
    required this.fromDate,
    required this.toDate,
    required this.totalBills,
    required this.distinctBrands,
    required this.totalQtyCase,
    required this.totalQtyLoose,
    required this.totalAmount,
    required this.totalTax,
    required this.items,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final int totalBills;
  final int distinctBrands;
  final int totalQtyCase;
  final int totalQtyLoose;
  final double totalAmount;
  final double totalTax;
  final List<SalesReportItemDto> items;

  factory SalesReportDto.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    return SalesReportDto(
      fromDate: DateTime.parse(json['fromDate'] as String),
      toDate: DateTime.parse(json['toDate'] as String),
      totalBills: json['totalBills'] as int,
      distinctBrands: json['distinctBrands'] as int,
      totalQtyCase: json['totalQtyCase'] as int,
      totalQtyLoose: json['totalQtyLoose'] as int,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      totalTax: (json['totalTax'] as num).toDouble(),
      items: itemsJson.map((e) => SalesReportItemDto.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
