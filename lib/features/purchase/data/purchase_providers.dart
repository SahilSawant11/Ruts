import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client_provider.dart';
import '../../masters/data/masters_providers.dart';
import '../../masters/data/models/supplier_dto.dart';
import 'local_purchase_repository.dart';
import 'models/purchase_return_models.dart';
import 'purchase_api_repository.dart';

final purchaseApiRepositoryProvider = Provider<PurchaseApiRepository>((ref) {
  return PurchaseApiRepository(ref.watch(httpClientProvider));
});

final purchaseRepositoryProvider = Provider<LocalPurchaseRepository>((ref) {
  return LocalPurchaseRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(purchaseApiRepositoryProvider),
    ref.watch(mastersRepositoryProvider),
  );
});

final suppliersProvider = FutureProvider<List<SupplierDto>>((ref) {
  return ref.watch(purchaseRepositoryProvider).getSuppliers();
});

final pendingPurchaseSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(purchaseRepositoryProvider).watchPendingPurchaseSyncCount();
});

class PurchaseReturnFilter {
  const PurchaseReturnFilter({this.search, this.date});
  final String? search;
  final DateTime? date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseReturnFilter &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          date?.year == other.date?.year &&
          date?.month == other.date?.month &&
          date?.day == other.date?.day;

  @override
  int get hashCode => Object.hash(search, date?.year, date?.month, date?.day);
}

final purchaseBillsListProvider = FutureProvider.family<List<PurchaseBillDetailDto>, PurchaseReturnFilter>((ref, filter) {
  return ref.watch(purchaseRepositoryProvider).getPurchaseBills(search: filter.search, date: filter.date);
});

final selectedPurchaseBillProvider = StateProvider<PurchaseBillDetailDto?>((ref) => null);
