/// Mirrors the `SalesBill` (+ nested `SaleLineItems`) shape returned by
/// GET /api/sales/today. Used for the "today's bills" list — not the
/// active cart, which lives in CartController instead.
class SalesBillDto {
  const SalesBillDto({
    required this.id,
    required this.billNo,
    required this.billDate,
    required this.payMode,
    required this.totalAmount,
    required this.balanceDue,
    required this.status,
    required this.lineItemCount,
  });

  final String id;
  final String billNo;
  final String billDate;
  final String payMode;
  final double totalAmount;
  final double balanceDue;
  final String status;
  final int lineItemCount;

  factory SalesBillDto.fromJson(Map<String, dynamic> json) {
    final lineItems = json['saleLineItems'] as List<dynamic>? ?? const [];
    return SalesBillDto(
      id: json['id'] as String,
      billNo: json['billNo'] as String,
      billDate: json['billDate'] as String,
      payMode: json['payMode'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      balanceDue: (json['balanceDue'] as num).toDouble(),
      status: json['status'] as String,
      lineItemCount: lineItems.length,
    );
  }
}
