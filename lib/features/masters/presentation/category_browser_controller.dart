import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/category_dto.dart';

class CategoryBrowserState {
  const CategoryBrowserState({
    this.categories = const [],
    this.index = -1,
    this.isEditing = false,
    this.isSaving = false,
  });

  final List<CategoryDto> categories;
  final int index;
  final bool isEditing;
  final bool isSaving;

  CategoryDto? get current => (index >= 0 && index < categories.length) ? categories[index] : null;
  bool get isNew => index == -1;
  bool get hasPrev => index > 0;
  bool get hasNext => index >= 0 && index < categories.length - 1;

  CategoryBrowserState copyWith({
    List<CategoryDto>? categories,
    int? index,
    bool? isEditing,
    bool? isSaving,
  }) {
    return CategoryBrowserState(
      categories: categories ?? this.categories,
      index: index ?? this.index,
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class CategoryBrowserController extends StateNotifier<CategoryBrowserState> {
  CategoryBrowserController() : super(const CategoryBrowserState());

  void syncList(List<CategoryDto> categories) {
    if (categories.isEmpty) {
      state = state.copyWith(categories: categories, index: -1);
      return;
    }
    final clampedIndex = state.index < 0 ? -1 : state.index.clamp(0, categories.length - 1);
    state = state.copyWith(categories: categories, index: clampedIndex);
  }

  void selectByName(String name) {
    final index = state.categories.indexWhere((category) => category.name == name);
    if (index != -1) {
      state = state.copyWith(index: index, isEditing: false);
    }
  }

  void prev() {
    if (state.hasPrev) state = state.copyWith(index: state.index - 1, isEditing: false);
  }

  void next() {
    if (state.hasNext) state = state.copyWith(index: state.index + 1, isEditing: false);
  }

  void startNew() => state = state.copyWith(index: -1, isEditing: true);
  void toggleEditing() => state = state.copyWith(isEditing: !state.isEditing);
  void setSaving(bool value) => state = state.copyWith(isSaving: value);

  void afterSave(List<CategoryDto> categories, String savedName) {
    final index = categories.indexWhere((category) => category.name == savedName);
    state = state.copyWith(
      categories: categories,
      index: index == -1 ? 0 : index,
      isEditing: false,
      isSaving: false,
    );
  }
}

final categoryBrowserProvider =
    StateNotifierProvider<CategoryBrowserController, CategoryBrowserState>((ref) {
  return CategoryBrowserController();
});
