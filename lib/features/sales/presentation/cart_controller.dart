import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../masters/data/masters_providers.dart';
import '../data/models/material_dto.dart';
import '../domain/sale_line_item.dart';

class CartState {
  const CartState({
    this.items = const [],
    this.isScanning = false,
    this.scanError,
  });

  final List<SaleLineItem> items;
  final bool isScanning;
  final String? scanError;

  int get totalQty => items.fold(0, (sum, i) => sum + i.qty);
  double get taxableValue => items.fold(0, (sum, i) => sum + i.taxableAmount);
  double get totalDiscount => items.fold(0, (sum, i) => sum + i.discountAmount);
  double get totalTax => items.fold(0, (sum, i) => sum + i.taxAmount);
  double get totalAmount => items.fold(0, (sum, i) => sum + i.amount);
  bool get isEmpty => items.isEmpty;
  bool get isLimitReached => items.length >= CartController.maxBottlesLimit || totalQty >= CartController.maxBottlesLimit;
  int get remainingBottles => (CartController.maxBottlesLimit - totalQty).clamp(0, CartController.maxBottlesLimit);

  CartState copyWith({List<SaleLineItem>? items, bool? isScanning, String? scanError, bool clearError = false}) {
    return CartState(
      items: items ?? this.items,
      isScanning: isScanning ?? this.isScanning,
      scanError: clearError ? null : (scanError ?? this.scanError),
    );
  }
}

/// Owns the line items for whatever bill is currently being built on
/// the Sales screen. Scanning a barcode looks the item up via the
/// in-memory [MaterialLookupCache] (O(1), no DB or network hit) and
/// appends a row.
/// Enforces the legal limit: 1 customer can take maximum 12 bottles per transaction.
class CartController extends StateNotifier<CartState> {
  CartController(this._findMaterial) : super(const CartState());

  static const int maxBottlesLimit = 12;

  /// Synchronous material lookup function (backed by in-memory cache).
  final MaterialDto? Function(String code) _findMaterial;

  /// Looks up the barcode in the in-memory cache and adds it to the cart.
  /// Returns true if the item was added, false on error.
  /// This method is effectively synchronous (no DB or network I/O).
  Future<bool> addByBarcode(String rawBarcode, {int qty = 1}) async {
    final sw = kDebugMode ? (Stopwatch()..start()) : null;

    final barcode = rawBarcode.trim();
    if (barcode.isEmpty) return false;
    final addQty = qty <= 0 ? 1 : qty;

    if (state.isLimitReached) {
      state = state.copyWith(
        scanError: 'Customer purchase limit reached: 1 customer can take only $maxBottlesLimit bottles.',
      );
      return false;
    }

    if (state.totalQty + addQty > maxBottlesLimit) {
      final remaining = maxBottlesLimit - state.totalQty;
      state = state.copyWith(
        scanError: 'Cannot add $addQty bottles. Only $remaining bottle${remaining == 1 ? '' : 's'} remaining under the $maxBottlesLimit-bottle limit.',
      );
      return false;
    }

    // Clear previous error.
    state = state.copyWith(clearError: true);

    // O(1) in-memory lookup — no DB query, no network call.
    final material = _findMaterial(barcode);
    if (material == null) {
      state = state.copyWith(scanError: 'No item found for barcode "$barcode".');
      return false;
    }

    // If it's already in the cart, bump the quantity instead of adding
    // a duplicate row.
    final existingIndex = state.items.indexWhere((i) => i.barcode == material.barcode);
    if (existingIndex != -1) {
      final updated = [...state.items];
      updated[existingIndex] = updated[existingIndex].copyWith(qty: updated[existingIndex].qty + addQty);
      state = state.copyWith(items: updated);

      if (kDebugMode) {
        sw!.stop();
        debugPrint('⏱ scan→UI (qty bump): ${sw.elapsedMilliseconds}ms');
      }
      return true;
    }

    final newItem = SaleLineItem.fromMaterial(material, index: state.items.length + 1, qty: addQty);
    state = state.copyWith(items: [...state.items, newItem]);

    if (kDebugMode) {
      sw!.stop();
      debugPrint('⏱ scan→UI (new item): ${sw.elapsedMilliseconds}ms');
    }
    return true;
  }

  void updateQty(int index, int newQty) {
    if (index < 0 || index >= state.items.length) return;
    if (newQty <= 0) {
      removeAt(index);
      return;
    }

    final currentItemQty = state.items[index].qty;
    final newTotalQty = state.totalQty - currentItemQty + newQty;
    if (newTotalQty > maxBottlesLimit) {
      state = state.copyWith(
        scanError: 'Cannot exceed $maxBottlesLimit bottles per customer under excise regulations.',
      );
      return;
    }

    final updated = [...state.items];
    updated[index] = updated[index].copyWith(qty: newQty);
    state = state.copyWith(items: updated, clearError: true);
  }

  void removeAt(int index) {
    final updated = [...state.items]..removeAt(index);
    final reindexed = [for (var i = 0; i < updated.length; i++) updated[i].copyWith(index: i + 1)];
    state = state.copyWith(items: reindexed);
  }

  void clear() => state = const CartState();
}

final cartControllerProvider = StateNotifierProvider<CartController, CartState>((ref) {
  return CartController((code) {
    return ref.read(materialLookupCacheProvider)?.findByBarcodeOrId(code);
  });
});
