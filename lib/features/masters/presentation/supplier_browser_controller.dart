import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/supplier_dto.dart';

class SupplierBrowserState {
  const SupplierBrowserState({
    this.suppliers = const [],
    this.index = -1,
    this.isEditing = false,
    this.isSaving = false,
  });

  final List<SupplierDto> suppliers;

  /// -1 means "new, blank record" mode (no existing supplier selected).
  final int index;
  final bool isEditing;
  final bool isSaving;

  SupplierDto? get current => (index >= 0 && index < suppliers.length) ? suppliers[index] : null;
  bool get isNew => index == -1;
  bool get hasPrev => index > 0;
  bool get hasNext => index >= 0 && index < suppliers.length - 1;

  SupplierBrowserState copyWith({
    List<SupplierDto>? suppliers,
    int? index,
    bool? isEditing,
    bool? isSaving,
  }) {
    return SupplierBrowserState(
      suppliers: suppliers ?? this.suppliers,
      index: index ?? this.index,
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Owns which supplier is currently shown in the single-record form,
/// Prev/Next browsing through the real list, "New" (blank record) mode,
/// and the Modify (edit-lock) toggle. Actual field values live in
/// TextEditingControllers on the widget — this only tracks *which*
/// record and *what mode*.
class SupplierBrowserController extends StateNotifier<SupplierBrowserState> {
  SupplierBrowserController() : super(const SupplierBrowserState());

  /// Called whenever suppliersListProvider resolves/refreshes. Keeps
  /// the current selection stable across reloads where possible.
  void syncList(List<SupplierDto> suppliers) {
    if (suppliers.isEmpty) {
      state = state.copyWith(suppliers: suppliers, index: -1);
      return;
    }
    final clampedIndex = state.index < 0 ? 0 : state.index.clamp(0, suppliers.length - 1);
    state = state.copyWith(suppliers: suppliers, index: clampedIndex);
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

  /// After a successful create/update, reload the list and land on the
  /// record that was just saved.
  void afterSave(List<SupplierDto> suppliers, String savedId) {
    final idx = suppliers.indexWhere((s) => s.id == savedId);
    state = state.copyWith(
      suppliers: suppliers,
      index: idx == -1 ? 0 : idx,
      isEditing: false,
      isSaving: false,
    );
  }
}

final supplierBrowserProvider =
    StateNotifierProvider<SupplierBrowserController, SupplierBrowserState>((ref) {
  return SupplierBrowserController();
});
