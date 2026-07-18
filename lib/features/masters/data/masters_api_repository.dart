import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import 'models/save_supplier_request.dart';
import 'models/supplier_dto.dart';

class MastersApiRepository {
  MastersApiRepository(this._client);

  final http.Client _client;
  static const _timeout = Duration(seconds: 8);
  static const _headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};

  Future<List<SupplierDto>> getSuppliers() async {
    final response = await _get('/api/suppliers');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => SupplierDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SupplierDto> createSupplier(SaveSupplierRequest request) async {
    final response = await _post('/api/suppliers', request.toJson());
    return SupplierDto.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<SupplierDto> updateSupplier(String id, SaveSupplierRequest request) async {
    final response = await _put('/api/suppliers/$id', request.toJson());
    return SupplierDto.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
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

  Future<http.Response> _put(String path, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .put(ApiConfig.uri(path), headers: _headers, body: jsonEncode(body))
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
