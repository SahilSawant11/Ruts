import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client_provider.dart';
import '../../masters/data/masters_providers.dart';
import '../../sales/data/sales_providers.dart';
import 'dashboard_api_repository.dart';
import 'local_dashboard_repository.dart';
import 'models/dashboard_summary_dto.dart';

final dashboardApiRepositoryProvider = Provider<DashboardApiRepository>((ref) {
  return DashboardApiRepository(ref.watch(httpClientProvider));
});

final dashboardRepositoryProvider = Provider<LocalDashboardRepository>((ref) {
  return LocalDashboardRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(dashboardApiRepositoryProvider),
    ref.watch(salesRepositoryProvider),
  );
});

final dashboardSummaryProvider = FutureProvider<DashboardSummaryDto>((ref) {
  return ref.watch(dashboardRepositoryProvider).getSummary();
});

/// The period selected in the dashboard header; drives KPIs, top
/// categories, top products and payment mix.
final dashboardPeriodProvider = StateProvider<DashboardPeriod>((ref) => DashboardPeriod.week);

/// Refreshed together with [dashboardSummaryProvider] wherever that one is
/// invalidated. (Watching the summary here made the dashboard rebuild the
/// summary mid-draw, which Flutter forbids.)
final dashboardSnapshotProvider = FutureProvider<DashboardPeriodSnapshot>((ref) {
  return ref.watch(dashboardRepositoryProvider).getPeriodSnapshot(ref.watch(dashboardPeriodProvider));
});
