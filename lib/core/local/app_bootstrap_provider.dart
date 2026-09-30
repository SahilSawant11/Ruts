import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/masters/data/masters_providers.dart';
import 'material_lookup_cache.dart';

final appBootstrapProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);

  // PRAGMAs are now set in AppDatabase.migration.beforeOpen (per-connection).

  // ── Seed starter data if tables are empty ─────────────────────────
  await db.ensureStarterData();

  // ── Warm the in-memory material lookup cache ──────────────────────
  final cache = await MaterialLookupCache.load(db);
  ref.read(materialLookupCacheProvider.notifier).state = cache;

  if (kDebugMode) {
    debugPrint('⏱ Bootstrap complete · ${cache.length} materials cached');
  }
});
