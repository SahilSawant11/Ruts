import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import 'models/create_sale_request.dart';
import 'models/customer_dto.dart';
import 'models/material_dto.dart';
import 'models/sales_bill_dto.dart';

/// The only place in the app that talks HTTP for the Sales module.
/// Screens/providers call these methods and get back typed models or a
/// thrown [ApiException] — no raw JSON or http package usage leaks
/// outside this file.
class SalesApiRepository {
  SalesApiRepository(this._client);

  final http.Client _client;

  static const _timeout = Duration(seconds: 8);
  static const _headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};

  Future<List<SalesBillDto>> getTodaysBills() async {
    final response = await _get('/api/sales/today');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => SalesBillDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Returns null if no material matches that barcode (404), rather than
  /// throwing — a "not found" is an expected, normal outcome of scanning.
  Future<MaterialDto?> getMaterialByBarcode(String barcode) async {
    try {
      final response = await _get('/api/materials/$barcode');
      return MaterialDto.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<CustomerDto>> getCustomers() async {
    final response = await _get('/api/customers');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => CustomerDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CreateSaleResult> createSale(CreateSaleRequest request) async {
    final response = await _post('/api/sales', request.toJson());
    return CreateSaleResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
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
