class LicenseHolderDto {
  const LicenseHolderDto({
    required this.id,
    required this.permitNo,
    required this.name,
    this.issuedDate,
    this.whereGranted,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String permitNo;
  final String name;
  final String? issuedDate;
  final String? whereGranted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'permitNo': permitNo,
        'name': name,
        'issuedDate': issuedDate,
        'whereGranted': whereGranted,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory LicenseHolderDto.fromJson(Map<String, dynamic> json) => LicenseHolderDto(
        id: json['id'] as String? ?? json['permitNo'] as String? ?? '',
        permitNo: json['permitNo'] as String? ?? '',
        name: json['name'] as String? ?? '',
        issuedDate: json['issuedDate'] as String?,
        whereGranted: json['whereGranted'] as String?,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
        updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      );

  LicenseHolderDto copyWith({
    String? id,
    String? permitNo,
    String? name,
    String? issuedDate,
    String? whereGranted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LicenseHolderDto(
      id: id ?? this.id,
      permitNo: permitNo ?? this.permitNo,
      name: name ?? this.name,
      issuedDate: issuedDate ?? this.issuedDate,
      whereGranted: whereGranted ?? this.whereGranted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
