import 'package:flutter/material.dart';
import '../../../core/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../masters/data/masters_providers.dart';
import '../../../core/network/http_client_provider.dart';
import '../../sales/data/sales_providers.dart';
import 'license_holder_report.dart';
import 'local_reports_repository.dart';
import 'models/sales_report_dto.dart';
import 'scm_upload_exporter.dart';
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

final reportExcelExporterProvider = Provider<ScmUploadExporter>((ref) {
  return ScmUploadExporter();
});

DateTime _startOfDay([DateTime? d]) {
  final now = d ?? AppClock.now();
  return DateTime(now.year, now.month, now.day, 0, 0, 0);
}

DateTime _endOfDay([DateTime? d]) {
  final now = d ?? AppClock.now();
  return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
}

/// The date & time range currently selected in the Reports screen. Defaults
/// to "today full day" (00:00:00 to 23:59:59).
final reportDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  return DateTimeRange(start: _startOfDay(), end: _endOfDay());
});

final reportCategoryFilterProvider = StateProvider<String?>((ref) => null);
final reportManufacturerFilterProvider = StateProvider<String?>((ref) => null);

/// Re-fetches automatically whenever reportDateRangeProvider changes.
final salesReportProvider = FutureProvider<SalesReportDto>((ref) {
  final range = ref.watch(reportDateRangeProvider);
  final category = ref.watch(reportCategoryFilterProvider);
  final manufacturer = ref.watch(reportManufacturerFilterProvider);
  return ref.watch(reportsRepositoryProvider).getSalesReport(
        from: range.start,
        to: range.end,
        category: category,
        manufacturer: manufacturer,
      );
});

final licenseHolderReportExporterProvider = Provider<LicenseHolderReportExporter>((ref) {
  return LicenseHolderReportExporter();
});

/// Quantity sold per license holder over the Reports screen's date range.
final licenseHolderReportProvider = FutureProvider<LicenseHolderReport>((ref) {
  final range = ref.watch(reportDateRangeProvider);
  return LicenseHolderReport.build(ref.watch(appDatabaseProvider), range.start, range.end);
});
