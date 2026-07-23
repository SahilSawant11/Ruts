import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/http_client_provider.dart';
import '../../masters/data/masters_providers.dart';
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

/// Live stock levels — only includes materials that have at least one
/// InventoryStock row (i.e. have been purchased at least once).
final inventoryListProvider = FutureProvider<List<InventoryItemDto>>((ref) {
  return ref.watch(inventoryRepositoryProvider).getInventory();
});

/// The full picture: every material in the catalog, merged with its
/// stock level (0 if never purchased). This is what the KPI row,
/// donut, category chart, and reorder chart should all read from —
/// using inventoryListProvider alone would silently omit materials
/// that have never been purchased, undercounting "Out of Stock".
final inventoryOverviewProvider = FutureProvider<List<InventoryOverviewItem>>((ref) async {
  final materials = await ref.watch(materialsListProvider.future);
  final stock = await ref.watch(inventoryListProvider.future);
  final stockByMaterial = {for (final s in stock) s.materialId: s};

  return materials.map((m) {
    final s = stockByMaterial[m.id];
    return InventoryOverviewItem(
      materialId: m.id,
      barcode: m.barcode,
      name: m.name,
      category: m.category,
      qtyOnHand: s?.qtyOnHand ?? 0,
      reorderLevel: s?.reorderLevel ?? 10,
    );
  }).toList();
});
