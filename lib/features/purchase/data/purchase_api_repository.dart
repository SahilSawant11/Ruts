import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../sales/data/models/material_dto.dart';
import 'models/create_purchase_request.dart';
import 'models/supplier_dto.dart';

/// The only place in the app that talks HTTP for the Purchase module.
/// Material lookup reuses the same GET /api/materials/{barcode}
/// endpoint Sales uses — it's the same table, just borrowed here for
/// entering a purchase line by barcode instead of a barcode scan sale.
class PurchaseApiRepository {
  PurchaseApiRepository(this._client);

  final http.Client _client;

  static const _timeout = Duration(seconds: 8);
  static const _headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};

  Future<List<SupplierDto>> getSuppliers() async {
    final response = await _get('/api/suppliers');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => SupplierDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Returns null if no material matches (404) — that's a normal,
  /// expected outcome of a barcode search, not an error.
  Future<MaterialDto?> getMaterialByBarcode(String barcode) async {
    try {
      final response = await _get('/api/materials/$barcode');
      return MaterialDto.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<CreatePurchaseResult> createPurchase(CreatePurchaseRequest request) async {
    final response = await _post('/api/purchases', request.toJson());
    return CreatePurchaseResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<http.Response> _get(String path) async {
    try {
      final response = await _client.get(ApiConfig.uri(path), headers: _headers).timeout(_timeout);
      return _unwrap(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.network();
    }
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .post(ApiConfig.uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _unwrap(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.network();
    }
  }

  http.Response _unwrap(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return response;
    throw ApiException.fromStatusCode(response.statusCode);
  }
}
