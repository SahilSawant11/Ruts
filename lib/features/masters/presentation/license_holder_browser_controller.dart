import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/license_holder_dto.dart';

class LicenseHolderBrowserState {
  const LicenseHolderBrowserState({
    this.licenseHolders = const [],
    this.index = -1,
    this.isEditing = false,
    this.isSaving = false,
  });

  final List<LicenseHolderDto> licenseHolders;
  final int index;
  final bool isEditing;
  final bool isSaving;

  LicenseHolderDto? get current =>
      (index >= 0 && index < licenseHolders.length) ? licenseHolders[index] : null;
  bool get isNew => index == -1;
  bool get hasPrev => index > 0;
  bool get hasNext => index >= 0 && index < licenseHolders.length - 1;

  LicenseHolderBrowserState copyWith({
    List<LicenseHolderDto>? licenseHolders,
    int? index,
    bool? isEditing,
    bool? isSaving,
  }) {
    return LicenseHolderBrowserState(
      licenseHolders: licenseHolders ?? this.licenseHolders,
      index: index ?? this.index,
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class LicenseHolderBrowserController extends StateNotifier<LicenseHolderBrowserState> {
  LicenseHolderBrowserController() : super(const LicenseHolderBrowserState());

  void syncList(List<LicenseHolderDto> list) {
    if (list.isEmpty) {
      state = state.copyWith(licenseHolders: list, index: -1);
      return;
    }
    final int clampedIndex;
    if (state.isNew && state.isEditing) {
      clampedIndex = -1;
    } else if (state.index < 0) {
      clampedIndex = 0;
    } else {
      clampedIndex = state.index.clamp(0, list.length - 1);
    }
    state = state.copyWith(licenseHolders: list, index: clampedIndex);
  }

  void selectById(String id, [List<LicenseHolderDto>? currentList]) {
    final list = (currentList != null && currentList.isNotEmpty)
        ? currentList
        : state.licenseHolders;
    final index = list.indexWhere((lh) => lh.id == id || lh.permitNo == id);
    if (index != -1) {
      state = state.copyWith(
        licenseHolders: list,
        index: index,
        isEditing: false,
      );
    } else if (list.isNotEmpty) {
      state = state.copyWith(licenseHolders: list);
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

  void afterSave(List<LicenseHolderDto> list, String savedPermitNo) {
    final index = list.indexWhere((lh) => lh.permitNo == savedPermitNo);
    state = state.copyWith(
      licenseHolders: list,
      index: index == -1 ? 0 : index,
      isEditing: false,
      isSaving: false,
    );
  }
}

final licenseHolderBrowserProvider =
    StateNotifierProvider<LicenseHolderBrowserController, LicenseHolderBrowserState>((ref) {
  return LicenseHolderBrowserController();
});
