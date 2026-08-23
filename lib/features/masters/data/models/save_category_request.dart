class SaveCategoryRequest {
  const SaveCategoryRequest({
    required this.name,
    this.description,
  });

  final String name;
  final String? description;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
      };
}
