/// Mirrors the `Customer` shape returned by GET /api/customers.
class CustomerDto {
  const CustomerDto({
    required this.id,
    required this.name,
    this.phone,
    required this.customerType,
    required this.balance,
  });

  final String id;
  final String name;
  final String? phone;
  final String customerType;
  final double balance;

  factory CustomerDto.fromJson(Map<String, dynamic> json) {
    return CustomerDto(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      customerType: json['customerType'] as String,
      balance: (json['balance'] as num).toDouble(),
    );
  }
}
