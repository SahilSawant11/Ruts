import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/http_client_provider.dart';
import 'models/inventory_item_dto.dart';

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

/// Live stock levels — this is what both the Inventory screen and (in
/// future) any "low stock" dashboard widget should read from instead
/// of hardcoded numbers.
final inventoryListProvider = FutureProvider<List<InventoryItemDto>>((ref) {
  return ref.watch(inventoryRepositoryProvider).getInventory();
});
