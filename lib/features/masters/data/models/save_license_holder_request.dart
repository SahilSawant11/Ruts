import 'license_holder_dto.dart';

class SaveLicenseHolderRequest {
  const SaveLicenseHolderRequest({
    required this.permitNo,
    required this.name,
    this.issuedDate,
    this.whereGranted,
    this.city,
    this.validity = LicenseHolderDto.lifetime,
    this.address,
    this.contactNo,
    this.remark,
    this.category = LicenseHolderDto.licenseHolder,
  });

  /// Empty for a Frequent Buyer.
  final String permitNo;
  final String name;
  final String? issuedDate;
  final String? whereGranted;
  final String? city;
  final String validity;
  final String? address;
  final String? contactNo;
  final String? remark;
  final String category;

  bool get isFrequentBuyer => category == LicenseHolderDto.frequentBuyer;

  Map<String, dynamic> toJson() => {
        'permitNo': permitNo,
        'name': name,
        'issuedDate': issuedDate,
        'whereGranted': whereGranted,
        'city': city,
        'validity': validity,
        'address': address,
        'contactNo': contactNo,
        'remark': remark,
        'category': category,
      };
}
