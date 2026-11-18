import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/local/app_database.dart';
import '../../../core/network/http_client_provider.dart';
import '../../sales/data/models/material_dto.dart';
import 'master_import_service.dart';
import 'master_template_service.dart';
import 'local_masters_repository.dart';
import 'masters_api_repository.dart';
import 'models/category_dto.dart';
import 'models/manufacturer_dto.dart';
import 'models/packaging_dto.dart';
import 'models/supplier_dto.dart';
import 'models/license_holder_dto.dart';
import '../../../core/local/material_lookup_cache.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.defaults();
  ref.onDispose(db.close);
  return db;
});

/// In-memory material lookup cache. Null until bootstrap completes.
/// Used by the scan path for O(1) barcode/item-code lookups.
final materialLookupCacheProvider = StateProvider<MaterialLookupCache?>((ref) => null);

final mastersApiRepositoryProvider = Provider<MastersApiRepository>((ref) {
  return MastersApiRepository(ref.watch(httpClientProvider));
});

final mastersRepositoryProvider = Provider<LocalMastersRepository>((ref) {
  return LocalMastersRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(mastersApiRepositoryProvider),
    onMaterialsChanged: () async {
      final db = ref.read(appDatabaseProvider);
      final cache = await MaterialLookupCache.load(db);
      ref.read(materialLookupCacheProvider.notifier).state = cache;
    },
  );
});

final masterTemplateServiceProvider = Provider<MasterTemplateService>((ref) => MasterTemplateService());

final masterImportServiceProvider = Provider<MasterImportService>((ref) {
  return MasterImportService(ref.watch(mastersRepositoryProvider));
});

final suppliersListProvider = FutureProvider<List<SupplierDto>>((ref) {
  return ref.watch(mastersRepositoryProvider).getSuppliers();
});

final materialsListProvider = FutureProvider<List<MaterialDto>>((ref) {
  return ref.watch(mastersRepositoryProvider).getMaterials();
});

final categoriesListProvider = FutureProvider<List<CategoryDto>>((ref) {
  return ref.watch(mastersRepositoryProvider).getCategories();
});

final manufacturersListProvider = FutureProvider<List<ManufacturerDto>>((ref) {
  return ref.watch(mastersRepositoryProvider).getManufacturers();
});

final packingsListProvider = FutureProvider<List<PackagingDto>>((ref) {
  return ref.watch(mastersRepositoryProvider).getPackings();
});

final licenseHoldersListProvider = FutureProvider<List<LicenseHolderDto>>((ref) {
  return ref.watch(mastersRepositoryProvider).getLicenseHolders();
});

/// Permits the sales screen rotates through (License Holders only, minus
/// used One Time permits). Refreshes with the master list; invalidate it
/// after each bill too.
final rotationLicenseHoldersProvider = FutureProvider<List<LicenseHolderDto>>((ref) async {
  await ref.watch(licenseHoldersListProvider.future);
  return ref.watch(mastersRepositoryProvider).getRotationLicenseHolders();
});

/// Frequent Buyers (name only) for the sales screen's customer menu.
final frequentBuyersProvider = FutureProvider<List<LicenseHolderDto>>((ref) async {
  final all = await ref.watch(licenseHoldersListProvider.future);
  return all.where((h) => h.isFrequentBuyer).toList();
});

final pendingMastersSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(mastersRepositoryProvider).watchPendingSyncCount();
});
