import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sales/data/models/material_dto.dart';

class MaterialBrowserState {
  const MaterialBrowserState({
    this.materials = const [],
    this.index = -1,
    this.isEditing = false,
    this.isSaving = false,
  });

  final List<MaterialDto> materials;

  /// -1 means "new, blank record" mode.
  final int index;
  final bool isEditing;
  final bool isSaving;

  MaterialDto? get current => (index >= 0 && index < materials.length) ? materials[index] : null;
  bool get isNew => index == -1;
  bool get hasPrev => index > 0;
  bool get hasNext => index >= 0 && index < materials.length - 1;

  MaterialBrowserState copyWith({
    List<MaterialDto>? materials,
    int? index,
    bool? isEditing,
    bool? isSaving,
  }) {
    return MaterialBrowserState(
      materials: materials ?? this.materials,
      index: index ?? this.index,
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Same browsing pattern as SupplierBrowserController: owns which
/// material is currently shown, Prev/Next through the real list, New
/// (blank record) mode, and the Modify (edit-lock) toggle.
class MaterialBrowserController extends StateNotifier<MaterialBrowserState> {
  MaterialBrowserController() : super(const MaterialBrowserState());

  void syncList(List<MaterialDto> materials) {
    if (materials.isEmpty) {
      state = state.copyWith(materials: materials, index: -1);
      return;
    }
    final clampedIndex = state.index < 0 ? 0 : state.index.clamp(0, materials.length - 1);
    state = state.copyWith(materials: materials, index: clampedIndex);
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

  void afterSave(List<MaterialDto> materials, String savedId) {
    final idx = materials.indexWhere((m) => m.id == savedId);
    state = state.copyWith(
      materials: materials,
      index: idx == -1 ? 0 : idx,
      isEditing: false,
      isSaving: false,
    );
  }
}

final materialBrowserProvider =
    StateNotifierProvider<MaterialBrowserController, MaterialBrowserState>((ref) {
  return MaterialBrowserController();
});
