/// Mirrors `CreatePurchaseRequest` on the API exactly.
class CreatePurchaseRequest {
  const CreatePurchaseRequest({
    required this.supplierId,
    this.billNo,
    this.challanNo,
    this.noteNo,
    required this.payMode,
    this.tpNo,
    this.tpDate,
    this.stNo,
    required this.discount,
    required this.vat,
    required this.stamp,
    required this.tcs,
    required this.loadingFreight,
    required this.netAmount,
    required this.totalAmount,
    required this.lineItems,
  });

  final String supplierId;
  final String? billNo;
  final String? challanNo;
  final String? noteNo;
  final String payMode;
  final String? tpNo;
  final String? tpDate; // yyyy-MM-dd
  final String? stNo;
  final double discount;
  final double vat;
  final double stamp;
  final double tcs;
  final double loadingFreight;
  final double netAmount;
  final double totalAmount;
  final List<CreatePurchaseLineItemRequest> lineItems;

  Map<String, dynamic> toJson() => {
        'supplierId': supplierId,
        'billNo': billNo,
        'challanNo': challanNo,
        'noteNo': noteNo,
        'payMode': payMode,
        'tpNo': tpNo,
        'tpDate': tpDate,
        'stNo': stNo,
        'discount': discount,
        'vat': vat,
        'stamp': stamp,
        'tcs': tcs,
        'loadingFreight': loadingFreight,
        'netAmount': netAmount,
        'totalAmount': totalAmount,
        'lineItems': lineItems.map((e) => e.toJson()).toList(),
      };
}

/// Mirrors `CreatePurchaseLineItemRequest` on the API exactly.
class CreatePurchaseLineItemRequest {
  const CreatePurchaseLineItemRequest({
    required this.materialId,
    required this.batchNo,
    this.packing,
    required this.qty,
    required this.rate,
    required this.disPercent,
    required this.disAmount,
    required this.taxPercent,
    required this.taxAmount,
    required this.amount,
  });

  final String materialId;
  final String batchNo;
  final String? packing;
  final int qty;
  final double rate;
  final double disPercent;
  final double disAmount;
  final double taxPercent;
  final double taxAmount;
  final double amount;

  Map<String, dynamic> toJson() => {
        'materialId': materialId,
        'batchNo': batchNo,
        'packing': packing,
        'qty': qty,
        'rate': rate,
        'disPercent': disPercent,
        'disAmount': disAmount,
        'taxPercent': taxPercent,
        'taxAmount': taxAmount,
        'amount': amount,
      };
}

/// What the server confirms back after a successful save.
class CreatePurchaseResult {
  const CreatePurchaseResult({required this.id, required this.billNo, required this.lineItemCount});

  final String id;
  final String? billNo;
  final int lineItemCount;

  factory CreatePurchaseResult.fromJson(Map<String, dynamic> json) => CreatePurchaseResult(
        id: json['id'] as String,
        billNo: json['billNo'] as String?,
        lineItemCount: json['lineItemCount'] as int,
      );
}
