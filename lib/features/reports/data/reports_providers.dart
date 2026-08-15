import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../masters/data/masters_providers.dart';
import '../../../core/network/http_client_provider.dart';
import '../../sales/data/sales_providers.dart';
import 'local_reports_repository.dart';
import 'models/sales_report_dto.dart';
import 'report_excel_exporter.dart';
import 'reports_api_repository.dart';

final reportsApiRepositoryProvider = Provider<ReportsApiRepository>((ref) {
  return ReportsApiRepository(ref.watch(httpClientProvider));
});

final reportsRepositoryProvider = Provider<LocalReportsRepository>((ref) {
  return LocalReportsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(reportsApiRepositoryProvider),
    ref.watch(salesRepositoryProvider),
  );
});

final reportExcelExporterProvider = Provider<ReportExcelExporter>((ref) {
  return ReportExcelExporter();
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
