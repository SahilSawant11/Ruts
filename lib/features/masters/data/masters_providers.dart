import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/local/app_database.dart';
import '../../../core/network/http_client_provider.dart';
import '../../sales/data/models/material_dto.dart';
import 'local_masters_repository.dart';
import 'masters_api_repository.dart';
import 'models/supplier_dto.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.defaults();
  ref.onDispose(db.close);
  return db;
});

final mastersApiRepositoryProvider = Provider<MastersApiRepository>((ref) {
  return MastersApiRepository(ref.watch(httpClientProvider));
});

final mastersRepositoryProvider = Provider<LocalMastersRepository>((ref) {
  return LocalMastersRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(mastersApiRepositoryProvider),
  );
});

final suppliersListProvider = FutureProvider<List<SupplierDto>>((ref) {
  return ref.watch(mastersRepositoryProvider).getSuppliers();
});

final materialsListProvider = FutureProvider<List<MaterialDto>>((ref) {
  return ref.watch(mastersRepositoryProvider).getMaterials();
});
