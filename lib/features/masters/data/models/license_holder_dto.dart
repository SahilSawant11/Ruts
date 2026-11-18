/// Permit holder master row. [category] is [LicenseHolderDto.licenseHolder]
/// (has a permit, joins the per-bill rotation) or
/// [LicenseHolderDto.frequentBuyer] (name only, never rotates).
class LicenseHolderDto {
  const LicenseHolderDto({
    required this.id,
    required this.permitNo,
    required this.name,
    this.issuedDate,
    this.whereGranted,
    this.city,
    this.validity = lifetime,
    this.address,
    this.contactNo,
    this.remark,
    this.category = licenseHolder,
    this.createdAt,
    this.updatedAt,
  });

  static const licenseHolder = 'License Holder';
  static const frequentBuyer = 'Frequent Buyer';
  static const categories = [licenseHolder, frequentBuyer];

  static const oneTime = 'One Time';
  static const lifetime = 'Lifetime';
  static const validities = [oneTime, lifetime];

  final String id;
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isFrequentBuyer => category == frequentBuyer;
  bool get isOneTime => validity == oneTime;

  Map<String, dynamic> toJson() => {
        'id': id,
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
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory LicenseHolderDto.fromJson(Map<String, dynamic> json) => LicenseHolderDto(
        id: json['id'] as String? ?? json['permitNo'] as String? ?? '',
        permitNo: json['permitNo'] as String? ?? '',
        name: json['name'] as String? ?? '',
        issuedDate: json['issuedDate'] as String?,
        whereGranted: json['whereGranted'] as String?,
        city: json['city'] as String?,
        validity: json['validity'] as String? ?? lifetime,
        address: json['address'] as String?,
        contactNo: json['contactNo'] as String?,
        remark: json['remark'] as String?,
        category: json['category'] as String? ?? licenseHolder,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
        updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      );

  LicenseHolderDto copyWith({
    String? id,
    String? permitNo,
    String? name,
    String? issuedDate,
    String? whereGranted,
    String? city,
    String? validity,
    String? address,
    String? contactNo,
    String? remark,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LicenseHolderDto(
      id: id ?? this.id,
      permitNo: permitNo ?? this.permitNo,
      name: name ?? this.name,
      issuedDate: issuedDate ?? this.issuedDate,
      whereGranted: whereGranted ?? this.whereGranted,
      city: city ?? this.city,
      validity: validity ?? this.validity,
      address: address ?? this.address,
      contactNo: contactNo ?? this.contactNo,
      remark: remark ?? this.remark,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
