import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/http_client_provider.dart';
import '../../masters/data/masters_providers.dart';
import 'local_inventory_repository.dart';
import 'models/inventory_item_dto.dart';
import 'models/inventory_overview_item.dart';

class InventoryApiRepository {
  InventoryApiRepository(this._client);

  final http.Client _client;
  static const _timeout = Duration(seconds: 8);

  Future<List<InventoryItemDto>> getInventory() async {
    try {
      final response = await _client
          .get(ApiConfig.uri('/api/inventory'), headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException.fromStatusCode(response.statusCode);
      }

      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => InventoryItemDto.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.network();
    }
  }
}

final inventoryRepositoryProvider = Provider<InventoryApiRepository>((ref) {
  return InventoryApiRepository(ref.watch(httpClientProvider));
});

final localInventoryRepositoryProvider = Provider<LocalInventoryRepository>((ref) {
  return LocalInventoryRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(inventoryRepositoryProvider),
    ref.watch(mastersRepositoryProvider),
  );
});

/// Live stock levels — only includes materials that have at least one
/// InventoryStock row (i.e. have been purchased at least once).
final inventoryListProvider = FutureProvider<List<InventoryItemDto>>((ref) {
  return ref.watch(localInventoryRepositoryProvider).getInventory();
});

/// The full picture: every material in the catalog, merged with its
/// stock level (0 if never purchased). This is what the KPI row,
/// donut, category chart, and reorder chart should all read from —
/// using inventoryListProvider alone would silently omit materials
/// that have never been purchased, undercounting "Out of Stock".
final inventoryOverviewProvider = FutureProvider<List<InventoryOverviewItem>>((ref) async {
  return ref.watch(localInventoryRepositoryProvider).getInventoryOverview();
});

final inventoryCategoryFilterProvider = StateProvider<String?>((ref) => null);
final inventoryManufacturerFilterProvider = StateProvider<String?>((ref) => null);
final inventoryStatusFilterProvider = StateProvider<String?>((ref) => null);
final inventorySearchFilterProvider = StateProvider<String>((ref) => '');

final inventoryManufacturerOptionsProvider = FutureProvider<List<String>>((ref) async {
  final items = await ref.watch(manufacturersListProvider.future);
  return items.map((item) => item.name).toList()..sort();
});

final filteredInventoryOverviewProvider = FutureProvider<List<InventoryOverviewItem>>((ref) async {
  final items = await ref.watch(inventoryOverviewProvider.future);
  final category = ref.watch(inventoryCategoryFilterProvider);
  final manufacturer = ref.watch(inventoryManufacturerFilterProvider);
  final status = ref.watch(inventoryStatusFilterProvider);
  final search = ref.watch(inventorySearchFilterProvider).trim().toLowerCase();

  return items.where((item) {
    final categoryMatch = category == null || category.isEmpty || item.category == category;
    final manufacturerMatch = manufacturer == null ||
        manufacturer.isEmpty ||
        item.manufacturer == manufacturer;
    final statusMatch = switch (status) {
      null || '' => true,
      'In Stock' => item.qtyOnHand > item.reorderLevel,
      'Low Stock' => item.qtyOnHand > 0 && item.qtyOnHand <= item.reorderLevel,
      'Out of Stock' => item.qtyOnHand <= 0,
      _ => true,
    };
    final searchMatch = search.isEmpty ||
        item.name.toLowerCase().contains(search) ||
        item.barcode.toLowerCase().contains(search) ||
        item.materialId.toLowerCase().contains(search) ||
        item.packing.toLowerCase().contains(search);
    return categoryMatch && manufacturerMatch && statusMatch && searchMatch;
  }).toList();
});
