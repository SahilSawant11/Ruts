import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import 'models/sales_report_dto.dart';

class ReportsApiRepository {
  ReportsApiRepository(this._client);

  final http.Client _client;
  static const _timeout = Duration(seconds: 10);

  Future<SalesReportDto> getSalesReport({required DateTime from, required DateTime to}) async {
    try {
      final response = await _client
          .get(
            ApiConfig.uri('/api/reports/sales', {
              'from': _isoDate(from),
              'to': _isoDate(to),
            }),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException.fromStatusCode(response.statusCode);
      }

      return SalesReportDto.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      // Don't blanket-label everything "network" — a parsing bug would
      // otherwise look identical to an unreachable server, which makes
      // this exact kind of issue much harder to diagnose.
      throw ApiException('Could not load the report: $e');
    }
  }

  String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
