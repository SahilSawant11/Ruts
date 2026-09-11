import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/packaging_dto.dart';

class PackagingBrowserState {
  const PackagingBrowserState({
    this.packings = const [],
    this.index = -1,
    this.isEditing = false,
    this.isSaving = false,
  });

  final List<PackagingDto> packings;
  final int index;
  final bool isEditing;
  final bool isSaving;

  PackagingDto? get current =>
      (index >= 0 && index < packings.length) ? packings[index] : null;
  bool get isNew => index == -1;
  bool get hasPrev => index > 0;
  bool get hasNext => index >= 0 && index < packings.length - 1;

  PackagingBrowserState copyWith({
    List<PackagingDto>? packings,
    int? index,
    bool? isEditing,
    bool? isSaving,
  }) {
    return PackagingBrowserState(
      packings: packings ?? this.packings,
      index: index ?? this.index,
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class PackagingBrowserController extends StateNotifier<PackagingBrowserState> {
  PackagingBrowserController() : super(const PackagingBrowserState());

  void syncList(List<PackagingDto> packings) {
    if (packings.isEmpty) {
      state = state.copyWith(packings: packings, index: -1);
      return;
    }
    final clampedIndex =
        state.index < 0 ? -1 : state.index.clamp(0, packings.length - 1);
    state = state.copyWith(packings: packings, index: clampedIndex);
  }

  void selectByName(String name) {
    final index = state.packings.indexWhere((p) => p.name == name);
    if (index != -1) {
      state = state.copyWith(index: index, isEditing: false);
    }
  }

  void prev() {
    if (state.hasPrev) {
      state = state.copyWith(index: state.index - 1, isEditing: false);
    }
  }

  void next() {
    if (state.hasNext) {
      state = state.copyWith(index: state.index + 1, isEditing: false);
    }
  }

  void startNew() => state = state.copyWith(index: -1, isEditing: true);
  void toggleEditing() => state = state.copyWith(isEditing: !state.isEditing);
  void setSaving(bool value) => state = state.copyWith(isSaving: value);

  void afterSave(List<PackagingDto> packings, String savedName) {
    final index = packings.indexWhere((p) => p.name == savedName);
    state = state.copyWith(
      packings: packings,
      index: index == -1 ? 0 : index,
      isEditing: false,
      isSaving: false,
    );
  }
}

final packagingBrowserProvider =
    StateNotifierProvider<PackagingBrowserController, PackagingBrowserState>((ref) {
  return PackagingBrowserController();
});
