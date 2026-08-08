import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client_provider.dart';
import '../../masters/data/masters_providers.dart';
import '../../masters/data/models/supplier_dto.dart';
import 'local_purchase_repository.dart';
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
