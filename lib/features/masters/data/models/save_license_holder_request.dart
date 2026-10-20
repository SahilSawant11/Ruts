class SaveLicenseHolderRequest {
  const SaveLicenseHolderRequest({
    required this.permitNo,
    required this.name,
    this.issuedDate,
    this.whereGranted,
  });

  final String permitNo;
  final String name;
  final String? issuedDate;
  final String? whereGranted;

  Map<String, dynamic> toJson() => {
        'permitNo': permitNo,
        'name': name,
        'issuedDate': issuedDate,
        'whereGranted': whereGranted,
      };
}
