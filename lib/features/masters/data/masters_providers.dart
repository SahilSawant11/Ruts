import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client_provider.dart';
import '../../sales/data/models/material_dto.dart';
import 'masters_api_repository.dart';
import 'models/supplier_dto.dart';

final mastersRepositoryProvider = Provider<MastersApiRepository>((ref) {
  return MastersApiRepository(ref.watch(httpClientProvider));
});

final suppliersListProvider = FutureProvider<List<SupplierDto>>((ref) {
  return ref.watch(mastersRepositoryProvider).getSuppliers();
});

final materialsListProvider = FutureProvider<List<MaterialDto>>((ref) {
  return ref.watch(mastersRepositoryProvider).getMaterials();
});
