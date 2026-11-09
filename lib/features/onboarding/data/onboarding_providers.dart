import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/local/material_lookup_cache.dart';
import '../../masters/data/masters_providers.dart';
import 'opening_stock_service.dart';

final openingStockServiceProvider = Provider<OpeningStockService>((ref) {
  return OpeningStockService(
    ref.watch(appDatabaseProvider),
    ref.watch(mastersRepositoryProvider),
    ref.watch(masterImportServiceProvider),
    onStockChanged: () async {
      // The billing lookup cache carries stock on hand; reload it.
      final cache = await MaterialLookupCache.load(ref.read(appDatabaseProvider));
      ref.read(materialLookupCacheProvider.notifier).state = cache;
    },
  );
});

/// Whether this store still has to enter its opening stock. Invalidate
/// after setup completes so the app moves on.
final needsOnboardingProvider = FutureProvider<bool>((ref) {
  return ref.watch(openingStockServiceProvider).needsOnboarding();
});
