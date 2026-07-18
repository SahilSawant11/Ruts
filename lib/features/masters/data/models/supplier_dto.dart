/// Mirrors the `Supplier` shape returned by GET /api/suppliers.
class SupplierDto {
  const SupplierDto({
    required this.id,
    required this.name,
    this.address,
    this.contactNo,
    this.email,
    this.vatNo,
    this.bankDetails,
    required this.disPercent,
    required this.openingBalance,
    required this.balanceType,
  });

  final String id;
  final String name;
  final String? address;
  final String? contactNo;
  final String? email;
  final String? vatNo;
  final String? bankDetails;
  final double disPercent;
  final double openingBalance;
  final String balanceType;

  factory SupplierDto.fromJson(Map<String, dynamic> json) {
    return SupplierDto(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      contactNo: json['contactNo'] as String?,
      email: json['email'] as String?,
      vatNo: json['vatNo'] as String?,
      bankDetails: json['bankDetails'] as String?,
      disPercent: (json['disPercent'] as num).toDouble(),
      openingBalance: (json['openingBalance'] as num).toDouble(),
      balanceType: json['balanceType'] as String,
    );
  }
}
