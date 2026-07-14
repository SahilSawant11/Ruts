import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client_provider.dart';
import 'models/customer_dto.dart';
import 'models/sales_bill_dto.dart';
import 'sales_api_repository.dart';

final salesRepositoryProvider = Provider<SalesApiRepository>((ref) {
  return SalesApiRepository(ref.watch(httpClientProvider));
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
