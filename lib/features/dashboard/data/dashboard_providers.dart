import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client_provider.dart';
import 'dashboard_api_repository.dart';
import 'models/dashboard_summary_dto.dart';

final dashboardRepositoryProvider = Provider<DashboardApiRepository>((ref) {
  return DashboardApiRepository(ref.watch(httpClientProvider));
});

final dashboardSummaryProvider = FutureProvider<DashboardSummaryDto>((ref) {
  return ref.watch(dashboardRepositoryProvider).getSummary();
});
