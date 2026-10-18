import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/manufacturer_dto.dart';

class ManufacturerBrowserState {
  const ManufacturerBrowserState({
    this.manufacturers = const [],
    this.index = -1,
    this.isEditing = false,
    this.isSaving = false,
  });

  final List<ManufacturerDto> manufacturers;
  final int index;
  final bool isEditing;
  final bool isSaving;

  ManufacturerDto? get current => (index >= 0 && index < manufacturers.length) ? manufacturers[index] : null;
  bool get isNew => index == -1;
  bool get hasPrev => index > 0;
  bool get hasNext => index >= 0 && index < manufacturers.length - 1;

  ManufacturerBrowserState copyWith({
    List<ManufacturerDto>? manufacturers,
    int? index,
    bool? isEditing,
    bool? isSaving,
  }) {
    return ManufacturerBrowserState(
      manufacturers: manufacturers ?? this.manufacturers,
      index: index ?? this.index,
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class ManufacturerBrowserController extends StateNotifier<ManufacturerBrowserState> {
  ManufacturerBrowserController() : super(const ManufacturerBrowserState());

  void syncList(List<ManufacturerDto> manufacturers) {
    if (manufacturers.isEmpty) {
      state = state.copyWith(manufacturers: manufacturers, index: -1);
      return;
    }
    final int clampedIndex;
    if (state.isNew && state.isEditing) {
      clampedIndex = -1;
    } else if (state.index < 0) {
      clampedIndex = 0;
    } else {
      clampedIndex = state.index.clamp(0, manufacturers.length - 1);
    }
    state = state.copyWith(manufacturers: manufacturers, index: clampedIndex);
  }

  void selectByName(String name, [List<ManufacturerDto>? currentList]) {
    final list = (currentList != null && currentList.isNotEmpty) ? currentList : state.manufacturers;
    final normalizedName = name.trim().toLowerCase();
    final index = list.indexWhere((m) => m.name.trim().toLowerCase() == normalizedName);
    if (index != -1) {
      state = state.copyWith(manufacturers: list, index: index, isEditing: false);
    } else if (list.isNotEmpty) {
      state = state.copyWith(manufacturers: list);
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

  void afterSave(List<ManufacturerDto> manufacturers, String savedName) {
    final index = manufacturers.indexWhere((manufacturer) => manufacturer.name == savedName);
    state = state.copyWith(
      manufacturers: manufacturers,
      index: index == -1 ? 0 : index,
      isEditing: false,
      isSaving: false,
    );
  }
}

final manufacturerBrowserProvider =
    StateNotifierProvider<ManufacturerBrowserController, ManufacturerBrowserState>((ref) {
  return ManufacturerBrowserController();
});
