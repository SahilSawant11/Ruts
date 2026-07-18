/// Used for both POST (create) and PUT (update) — same field shape
/// either way, id is passed separately in the URL for updates.
class SaveSupplierRequest {
  const SaveSupplierRequest({
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

  final String name;
  final String? address;
  final String? contactNo;
  final String? email;
  final String? vatNo;
  final String? bankDetails;
  final double disPercent;
  final double openingBalance;
  final String balanceType;

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'contactNo': contactNo,
        'email': email,
        'vatNo': vatNo,
        'bankDetails': bankDetails,
        'disPercent': disPercent,
        'openingBalance': openingBalance,
        'balanceType': balanceType,
      };
}
