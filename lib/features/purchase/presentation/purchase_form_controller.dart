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
    this.vat = 0,
    this.stamp = 0,
    this.tcs = 0,
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
  final double vat;
  final double stamp;
  final double tcs;
  final double loadingFreight;

  double get extraCharges => vat + stamp + tcs + loadingFreight - discount;

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
    double? vat,
    double? stamp,
    double? tcs,
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
      vat: vat ?? this.vat,
      stamp: stamp ?? this.stamp,
      tcs: tcs ?? this.tcs,
      loadingFreight: loadingFreight ?? this.loadingFreight,
    );
  }
}

class PurchaseFormController extends StateNotifier<PurchaseFormState> {
  PurchaseFormController() : super(const PurchaseFormState());

  void setSupplier(String? id) => state = state.copyWith(supplierId: id);
  void setChallanNo(String v) => state = state.copyWith(challanNo: v);
  void setNoteNo(String v) => state = state.copyWith(noteNo: v);
  void setPayMode(String v) => state = state.copyWith(payMode: v);
  void setTpNo(String v) => state = state.copyWith(tpNo: v);
  void setStNo(String v) => state = state.copyWith(stNo: v);
  void setDiscount(double v) => state = state.copyWith(discount: v);
  void setVat(double v) => state = state.copyWith(vat: v);
  void setStamp(double v) => state = state.copyWith(stamp: v);
  void setTcs(double v) => state = state.copyWith(tcs: v);
  void setLoadingFreight(double v) => state = state.copyWith(loadingFreight: v);

  void reset() => state = const PurchaseFormState();
}

final purchaseFormControllerProvider =
    StateNotifierProvider<PurchaseFormController, PurchaseFormState>((ref) => PurchaseFormController());
