import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client_provider.dart';
import 'models/sales_report_dto.dart';
import 'reports_api_repository.dart';

final reportsRepositoryProvider = Provider<ReportsApiRepository>((ref) {
  return ReportsApiRepository(ref.watch(httpClientProvider));
});

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// The date range currently selected in the Reports screen. Defaults
/// to "today only" (Day-wise). Switching tabs or picking dates in the
/// filter card both just update this one provider.
final reportDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final today = _today();
  return DateTimeRange(start: today, end: today);
});

/// Re-fetches automatically whenever reportDateRangeProvider changes.
final salesReportProvider = FutureProvider<SalesReportDto>((ref) {
  final range = ref.watch(reportDateRangeProvider);
  return ref.watch(reportsRepositoryProvider).getSalesReport(from: range.start, to: range.end);
});
