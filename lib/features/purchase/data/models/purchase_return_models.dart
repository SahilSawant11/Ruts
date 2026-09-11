class PurchaseBillDetailDto {
  const PurchaseBillDetailDto({
    required this.id,
    this.billNo,
    required this.supplierId,
    required this.supplierName,
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
    required this.billDate,
    required this.status,
    required this.createdAt,
    this.lineItems = const [],
  });

  final String id;
  final String? billNo;
  final String supplierId;
  final String supplierName;
  final String? challanNo;
  final String? noteNo;
  final String payMode;
  final String? tpNo;
  final String? tpDate;
  final String? stNo;
  final double discount;
  final double vat;
  final double stamp;
  final double tcs;
  final double loadingFreight;
  final double netAmount;
  final double totalAmount;
  final String billDate;
  final String status;
  final String createdAt;
  final List<PurchaseLineItemDetailDto> lineItems;

  factory PurchaseBillDetailDto.fromJson(Map<String, dynamic> json) {
    final rawLines = json['purchaseLineItems'] as List<dynamic>? ?? const [];
    final items = rawLines
        .map((e) => PurchaseLineItemDetailDto.fromJson(e as Map<String, dynamic>))
        .toList();

    return PurchaseBillDetailDto(
      id: json['id']?.toString() ?? '',
      billNo: json['billNo']?.toString(),
      supplierId: json['supplierId']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? 'Supplier',
      challanNo: json['challanNo']?.toString(),
      noteNo: json['noteNo']?.toString(),
      payMode: json['payMode']?.toString() ?? 'Credit',
      tpNo: json['tpNo']?.toString(),
      tpDate: json['tpDate']?.toString(),
      stNo: json['stNo']?.toString(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      vat: (json['vat'] as num?)?.toDouble() ?? 0.0,
      stamp: (json['stamp'] as num?)?.toDouble() ?? 0.0,
      tcs: (json['tcs'] as num?)?.toDouble() ?? 0.0,
      loadingFreight: (json['loadingFreight'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      billDate: json['billDate']?.toString() ?? '',
      status: json['status']?.toString() ?? 'saved',
      createdAt: json['createdAt']?.toString() ?? '',
      lineItems: items,
    );
  }
}

class PurchaseLineItemDetailDto {
  const PurchaseLineItemDetailDto({
    required this.id,
    required this.purchaseBillId,
    required this.materialId,
    required this.materialName,
    required this.batchNo,
    this.packing,
    required this.qty,
    required this.rate,
    this.disPercent = 0.0,
    this.disAmount = 0.0,
    this.taxPercent = 0.0,
    this.taxAmount = 0.0,
    required this.amount,
    required this.lineNumber,
  });

  final String id;
  final String purchaseBillId;
  final String materialId;
  final String materialName;
  final String batchNo;
  final String? packing;
  final int qty;
  final double rate;
  final double disPercent;
  final double disAmount;
  final double taxPercent;
  final double taxAmount;
  final double amount;
  final int lineNumber;

  factory PurchaseLineItemDetailDto.fromJson(Map<String, dynamic> json) {
    return PurchaseLineItemDetailDto(
      id: json['id']?.toString() ?? '',
      purchaseBillId: json['purchaseBillId']?.toString() ?? '',
      materialId: json['materialId']?.toString() ?? '',
      materialName: json['materialName']?.toString() ?? '',
      batchNo: json['batchNo']?.toString() ?? '-',
      packing: json['packing']?.toString(),
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      disPercent: (json['disPercent'] as num?)?.toDouble() ?? 0.0,
      disAmount: (json['disAmount'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      lineNumber: (json['lineNumber'] as num?)?.toInt() ?? 1,
    );
  }
}
