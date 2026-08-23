class CategoryDto {
  const CategoryDto({
    required this.name,
    this.description,
    this.isPendingSync = false,
  });

  final String name;
  final String? description;
  final bool isPendingSync;
}
