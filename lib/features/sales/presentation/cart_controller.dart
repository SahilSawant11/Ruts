import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../data/sales_api_repository.dart';
import '../data/sales_providers.dart';
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

  CartState copyWith({List<SaleLineItem>? items, bool? isScanning, String? scanError, bool clearError = false}) {
    return CartState(
      items: items ?? this.items,
      isScanning: isScanning ?? this.isScanning,
      scanError: clearError ? null : (scanError ?? this.scanError),
    );
  }
}

/// Owns the line items for whatever bill is currently being built on
/// the Sales screen. Scanning a barcode looks the item up via the API
/// and appends a row; saving the bill (in PaymentCard) reads `items`
/// straight off this controller's state.
class CartController extends StateNotifier<CartState> {
  CartController(this._repo) : super(const CartState());

  final SalesApiRepository _repo;

  Future<void> addByBarcode(String rawBarcode) async {
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty) return;

    state = state.copyWith(isScanning: true, clearError: true);
    try {
      final material = await _repo.getMaterialByBarcode(barcode);
      if (material == null) {
        state = state.copyWith(isScanning: false, scanError: 'No item found for barcode "$barcode".');
        return;
      }

      // If it's already in the cart, bump the quantity instead of adding
      // a duplicate row.
      final existingIndex = state.items.indexWhere((i) => i.barcode == material.barcode);
      if (existingIndex != -1) {
        final updated = [...state.items];
        updated[existingIndex] = updated[existingIndex].copyWith(qty: updated[existingIndex].qty + 1);
        state = state.copyWith(items: updated, isScanning: false);
        return;
      }

      final newItem = SaleLineItem.fromMaterial(material, index: state.items.length + 1);
      state = state.copyWith(items: [...state.items, newItem], isScanning: false);
    } on ApiException catch (e) {
      state = state.copyWith(isScanning: false, scanError: e.message);
    }
  }

  void removeAt(int index) {
    final updated = [...state.items]..removeAt(index);
    final reindexed = [for (var i = 0; i < updated.length; i++) updated[i].copyWith(index: i + 1)];
    state = state.copyWith(items: reindexed);
  }

  void clear() => state = const CartState();
}

final cartControllerProvider = StateNotifierProvider<CartController, CartState>((ref) {
  return CartController(ref.watch(salesRepositoryProvider));
});
