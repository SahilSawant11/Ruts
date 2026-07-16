import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/purchase_line_item.dart';

class PurchaseCartState {
  const PurchaseCartState({this.items = const []});

  final List<PurchaseLineItem> items;

  double get itemsAmount => items.fold(0, (sum, i) => sum + i.amount);
  bool get isEmpty => items.isEmpty;

  PurchaseCartState copyWith({List<PurchaseLineItem>? items}) {
    return PurchaseCartState(items: items ?? this.items);
  }
}

/// Owns the line items for the purchase bill currently being entered.
/// Unlike Sales (which adds a line straight from a barcode scan),
/// Purchase needs batch/qty/rate/discount/tax per line, so lines are
/// added via the "Add Material Line" dialog rather than a bare scan.
class PurchaseCartController extends StateNotifier<PurchaseCartState> {
  PurchaseCartController() : super(const PurchaseCartState());

  void addLine(PurchaseLineItem item) {
    state = state.copyWith(items: [...state.items, item.copyWith(index: state.items.length + 1)]);
  }

  void removeAt(int index) {
    final updated = [...state.items]..removeAt(index);
    final reindexed = [for (var i = 0; i < updated.length; i++) updated[i].copyWith(index: i + 1)];
    state = state.copyWith(items: reindexed);
  }

  void clear() => state = const PurchaseCartState();
}

final purchaseCartControllerProvider =
    StateNotifierProvider<PurchaseCartController, PurchaseCartState>((ref) => PurchaseCartController());
