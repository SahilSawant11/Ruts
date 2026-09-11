class SalesBillDetailDto {
  const SalesBillDetailDto({
    required this.id,
    required this.billNo,
    this.customerId,
    this.customerName,
    required this.billType,
    required this.billDate,
    required this.payMode,
    required this.taxableValue,
    required this.totalDiscount,
    required this.totalTax,
    required this.totalAmount,
    required this.balanceDue,
    required this.status,
    required this.createdAt,
    this.lineItems = const [],
  });

  final String id;
  final String billNo;
  final String? customerId;
  final String? customerName;
  final String billType;
  final String billDate;
  final String payMode;
  final double taxableValue;
  final double totalDiscount;
  final double totalTax;
  final double totalAmount;
  final double balanceDue;
  final String status;
  final String createdAt;
  final List<SaleLineItemDetailDto> lineItems;

  factory SalesBillDetailDto.fromJson(Map<String, dynamic> json) {
    final rawLines = json['saleLineItems'] as List<dynamic>? ?? const [];
    final items = rawLines
        .map((e) => SaleLineItemDetailDto.fromJson(e as Map<String, dynamic>))
        .toList();

    return SalesBillDetailDto(
      id: json['id']?.toString() ?? '',
      billNo: json['billNo']?.toString() ?? '',
      customerId: json['customerId']?.toString(),
      customerName: json['customerName']?.toString(),
      billType: json['billType']?.toString() ?? 'CounterSale.Sale',
      billDate: json['billDate']?.toString() ?? '',
      payMode: json['payMode']?.toString() ?? 'Cash',
      taxableValue: (json['taxableValue'] as num?)?.toDouble() ?? 0.0,
      totalDiscount: (json['totalDiscount'] as num?)?.toDouble() ?? 0.0,
      totalTax: (json['totalTax'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (json['balanceDue'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'paid',
      createdAt: json['createdAt']?.toString() ?? '',
      lineItems: items,
    );
  }
}

class SaleLineItemDetailDto {
  const SaleLineItemDetailDto({
    required this.id,
    required this.salesBillId,
    required this.barcodeNo,
    this.materialId,
    required this.materialType,
    required this.materialName,
    this.batchNo,
    this.packing,
    required this.quantity,
    this.qtyCase = 0,
    required this.rate,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.taxPercent = 0.0,
    this.taxAmount = 0.0,
    required this.amount,
    required this.lineNumber,
  });

  final String id;
  final String salesBillId;
  final String barcodeNo;
  final String? materialId;
  final String materialType;
  final String materialName;
  final String? batchNo;
  final String? packing;
  final int quantity;
  final int qtyCase;
  final double rate;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double amount;
  final int lineNumber;

  factory SaleLineItemDetailDto.fromJson(Map<String, dynamic> json) {
    return SaleLineItemDetailDto(
      id: json['id']?.toString() ?? '',
      salesBillId: json['salesBillId']?.toString() ?? '',
      barcodeNo: json['barcodeNo']?.toString() ?? '',
      materialId: json['materialId']?.toString(),
      materialType: json['materialType']?.toString() ?? '',
      materialName: json['materialName']?.toString() ?? '',
      batchNo: json['batchNo']?.toString(),
      packing: json['packing']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      qtyCase: (json['qtyCase'] as num?)?.toInt() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      lineNumber: (json['lineNumber'] as num?)?.toInt() ?? 1,
    );
  }
}
