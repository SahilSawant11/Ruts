class SaveManufacturerRequest {
  const SaveManufacturerRequest({
    required this.name,
    this.description,
  });

  final String name;
  final String? description;
}
