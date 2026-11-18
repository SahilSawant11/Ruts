import 'package:flutter_riverpod/flutter_riverpod.dart';

class PurchaseFormState {
  const PurchaseFormState({
    this.supplierId,
    this.billNo,
    this.challanNo,
    this.noteNo,
    this.payMode = 'Credit',
    this.tpNo,
    this.tpDate,
    this.stNo,
    this.discount = 0,
    this.vatPercent = 0,
    this.otherCharges = 0,
    this.tcsPercent = 0,
    this.loadingFreight = 0,
  });

  final String? supplierId;
  final String? billNo;
  final String? challanNo;
  final String? noteNo;
  final String payMode;
  final String? tpNo;
  final DateTime? tpDate;
  final String? stNo;
  final double discount;

  /// VAT % on the goods value (items total − discount).
  final double vatPercent;

  /// Other / breakage charges in ₹ (stored in the bill's `stamp` column,
  /// which used to hold stamp duty).
  final double otherCharges;

  /// TCS % on goods value + VAT.
  final double tcsPercent;
  final double loadingFreight;

  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  /// Goods value the percentages apply to; never negative.
  double _goods(double itemsAmount) {
    final g = itemsAmount - discount;
    return g < 0 ? 0 : g;
  }

  double vatAmount(double itemsAmount) => _round2(_goods(itemsAmount) * vatPercent / 100);

  double tcsAmount(double itemsAmount) =>
      _round2((_goods(itemsAmount) + vatAmount(itemsAmount)) * tcsPercent / 100);

  /// Everything added on top of the items total (discount subtracts).
  double extraCharges(double itemsAmount) =>
      vatAmount(itemsAmount) + otherCharges + tcsAmount(itemsAmount) + loadingFreight - discount;

  PurchaseFormState copyWith({
    String? supplierId,
    String? billNo,
    String? challanNo,
    String? noteNo,
    String? payMode,
    String? tpNo,
    DateTime? tpDate,
    String? stNo,
    double? discount,
    double? vatPercent,
    double? otherCharges,
    double? tcsPercent,
    double? loadingFreight,
  }) {
    return PurchaseFormState(
      supplierId: supplierId ?? this.supplierId,
      billNo: billNo ?? this.billNo,
      challanNo: challanNo ?? this.challanNo,
      noteNo: noteNo ?? this.noteNo,
      payMode: payMode ?? this.payMode,
      tpNo: tpNo ?? this.tpNo,
      tpDate: tpDate ?? this.tpDate,
      stNo: stNo ?? this.stNo,
      discount: discount ?? this.discount,
      vatPercent: vatPercent ?? this.vatPercent,
      otherCharges: otherCharges ?? this.otherCharges,
      tcsPercent: tcsPercent ?? this.tcsPercent,
      loadingFreight: loadingFreight ?? this.loadingFreight,
    );
  }
}

class PurchaseFormController extends StateNotifier<PurchaseFormState> {
  PurchaseFormController() : super(const PurchaseFormState());

  void setSupplier(String? id) => state = state.copyWith(supplierId: id);

  /// Picks the item's default distributor when no supplier is chosen yet.
  /// Never overrides a supplier the user already picked.
  void prefillSupplier(String defaultSupplierId) {
    final id = defaultSupplierId.trim();
    if (id.isEmpty || (state.supplierId?.isNotEmpty ?? false)) return;
    state = state.copyWith(supplierId: id);
  }
  void setChallanNo(String v) => state = state.copyWith(challanNo: v);
  void setNoteNo(String v) => state = state.copyWith(noteNo: v);
  void setPayMode(String v) => state = state.copyWith(payMode: v);
  void setTpNo(String v) => state = state.copyWith(tpNo: v);
  void setStNo(String v) => state = state.copyWith(stNo: v);
  void setDiscount(double v) => state = state.copyWith(discount: v);
  void setVatPercent(double v) => state = state.copyWith(vatPercent: v);
  void setOtherCharges(double v) => state = state.copyWith(otherCharges: v);
  void setTcsPercent(double v) => state = state.copyWith(tcsPercent: v);
  void setLoadingFreight(double v) => state = state.copyWith(loadingFreight: v);

  void reset() => state = const PurchaseFormState();
}

final purchaseFormControllerProvider =
    StateNotifierProvider<PurchaseFormController, PurchaseFormState>((ref) => PurchaseFormController());
