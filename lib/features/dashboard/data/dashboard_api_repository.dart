import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import 'models/dashboard_summary_dto.dart';

class DashboardApiRepository {
  DashboardApiRepository(this._client);

  final http.Client _client;
  static const _timeout = Duration(seconds: 10);

  Future<DashboardSummaryDto> getSummary() async {
    try {
      final response = await _client
          .get(ApiConfig.uri('/api/dashboard/summary'), headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException.fromStatusCode(response.statusCode);
      }

      return DashboardSummaryDto.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Could not load the dashboard: $e');
    }
  }
}
