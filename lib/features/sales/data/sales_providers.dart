import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client_provider.dart';
import '../../masters/data/masters_providers.dart';
import 'models/customer_dto.dart';
import 'models/sales_bill_dto.dart';
import 'models/sales_return_models.dart';
import 'local_sales_repository.dart';
import 'sales_api_repository.dart';

final salesApiRepositoryProvider = Provider<SalesApiRepository>((ref) {
  return SalesApiRepository(ref.watch(httpClientProvider));
});

final salesRepositoryProvider = Provider<LocalSalesRepository>((ref) {
  return LocalSalesRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(salesApiRepositoryProvider),
    ref.watch(mastersRepositoryProvider),
  );
});

/// Customer dropdown options. `.refresh()` from a widget via
/// `ref.invalidate(customersProvider)` if you need to force a reload
/// after adding a customer elsewhere.
final customersProvider = FutureProvider<List<CustomerDto>>((ref) {
  return ref.watch(salesRepositoryProvider).getCustomers();
});

/// Today's saved bills — not the active cart. Used for a future
/// "Find / Edit Sale" panel; invalidate this after a successful save
/// so it reflects the newly created bill.
final todaysBillsProvider = FutureProvider<List<SalesBillDto>>((ref) {
  return ref.watch(salesRepositoryProvider).getTodaysBills();
});

final pendingSalesSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(salesRepositoryProvider).watchPendingSalesSyncCount();
});

class SalesReturnFilter {
  const SalesReturnFilter({this.search, this.date});
  final String? search;
  final DateTime? date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesReturnFilter &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          date?.year == other.date?.year &&
          date?.month == other.date?.month &&
          date?.day == other.date?.day;

  @override
  int get hashCode => Object.hash(search, date?.year, date?.month, date?.day);
}

final salesBillsListProvider = FutureProvider.family<List<SalesBillDetailDto>, SalesReturnFilter>((ref, filter) {
  return ref.watch(salesRepositoryProvider).getSalesBills(search: filter.search, date: filter.date);
});

final selectedSalesBillProvider = StateProvider<SalesBillDetailDto?>((ref) => null);
