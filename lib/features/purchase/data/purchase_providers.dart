import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client_provider.dart';
import 'models/supplier_dto.dart';
import 'purchase_api_repository.dart';

final purchaseRepositoryProvider = Provider<PurchaseApiRepository>((ref) {
  return PurchaseApiRepository(ref.watch(httpClientProvider));
});

final suppliersProvider = FutureProvider<List<SupplierDto>>((ref) {
  return ref.watch(purchaseRepositoryProvider).getSuppliers();
});
