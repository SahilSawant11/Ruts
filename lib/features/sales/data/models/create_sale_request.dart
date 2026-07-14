/// Mirrors `CreateSaleRequest` on the API exactly — field names and
/// casing must match what System.Text.Json expects (camelCase).
class CreateSaleRequest {
  const CreateSaleRequest({
    required this.billNo,
    this.customerId,
    required this.payMode,
    required this.taxableValue,
    required this.totalDiscount,
    required this.totalTax,
    required this.totalAmount,
    required this.balanceDue,
    required this.lineItems,
  });

  final String billNo;
  final String? customerId;
  final String payMode;
  final double taxableValue;
  final double totalDiscount;
  final double totalTax;
  final double totalAmount;
  final double balanceDue;
  final List<CreateSaleLineItemRequest> lineItems;

  Map<String, dynamic> toJson() => {
        'billNo': billNo,
        'customerId': customerId,
        'payMode': payMode,
        'taxableValue': taxableValue,
        'totalDiscount': totalDiscount,
        'totalTax': totalTax,
        'totalAmount': totalAmount,
        'balanceDue': balanceDue,
        'lineItems': lineItems.map((e) => e.toJson()).toList(),
      };
}

/// Mirrors `CreateSaleLineItemRequest` on the API exactly.
class CreateSaleLineItemRequest {
  const CreateSaleLineItemRequest({
    required this.barcodeNo,
    required this.materialType,
    required this.materialName,
    this.batchNo,
    this.packing,
    required this.quantity,
    required this.rate,
    required this.discountPercent,
    required this.discountAmount,
    required this.taxPercent,
    required this.taxAmount,
    required this.amount,
  });

  final String barcodeNo;
  final String materialType;
  final String materialName;
  final String? batchNo;
  final String? packing;
  final int quantity;
  final double rate;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double amount;

  Map<String, dynamic> toJson() => {
        'barcodeNo': barcodeNo,
        'materialType': materialType,
        'materialName': materialName,
        'batchNo': batchNo,
        'packing': packing,
        'quantity': quantity,
        'rate': rate,
        'discountPercent': discountPercent,
        'discountAmount': discountAmount,
        'taxPercent': taxPercent,
        'taxAmount': taxAmount,
        'amount': amount,
      };
}

/// What the server confirms back after a successful save.
class CreateSaleResult {
  const CreateSaleResult({required this.id, required this.billNo, required this.lineItemCount});

  final String id;
  final String billNo;
  final int lineItemCount;

  factory CreateSaleResult.fromJson(Map<String, dynamic> json) => CreateSaleResult(
        id: json['id'] as String,
        billNo: json['billNo'] as String,
        lineItemCount: json['lineItemCount'] as int,
      );
}
