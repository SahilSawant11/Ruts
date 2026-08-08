import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/local/app_database.dart';
import '../../masters/data/masters_providers.dart';
import '../../purchase/data/purchase_providers.dart';
import '../../sales/data/sales_providers.dart';
import 'sync_repository.dart';

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(mastersRepositoryProvider),
    ref.watch(purchaseRepositoryProvider),
    ref.watch(salesRepositoryProvider),
  );
});

final syncOverviewProvider = StreamProvider<SyncOverview>((ref) {
  return ref.watch(syncRepositoryProvider).watchOverview();
});

final syncQueueItemsProvider = StreamProvider<List<SyncQueueItem>>((ref) {
  return ref.watch(syncRepositoryProvider).watchQueueItems();
});
