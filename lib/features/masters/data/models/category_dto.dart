class CategoryDto {
  const CategoryDto({
    required this.name,
    this.description,
  });

  final String name;
  final String? description;
}
