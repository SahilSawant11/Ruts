import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/masters/data/masters_providers.dart';
import '../../features/settings/data/settings_providers.dart';
import '../auth/auth_controller.dart';
import '../logging/app_logger.dart';
import '../theme/appearance_prefs.dart';
import '../sync/sync_providers.dart';
import 'db_paths.dart';
import 'material_lookup_cache.dart';

final appBootstrapProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final sw = Stopwatch()..start();

  // PRAGMAs are set in AppDatabase.migration.beforeOpen (per-connection).

  // ── Seed lookup data once (demo transactions only in demo builds) ──
  await db.ensureStarterData();
  if (!DbPaths.seedDemoData) {
    final purged = await db.purgeDemoData();
    if (purged > 0) AppLogger.info('Startup', 'Removed $purged demo bills left by a debug build');
  }
  await db.deviceId();
  await ref.read(authRepositoryProvider).ensureDefaultUsers();
  await restoreAndPersistAppearance(ref, db);

  // ── Warm the in-memory material lookup cache ──────────────────────
  final cache = await MaterialLookupCache.load(db);
  ref.read(materialLookupCacheProvider.notifier).state = cache;

  // ── Daily automatic backup (never blocks or fails startup) ─────────
  final backup = await ref.read(backupServiceProvider).autoBackupIfDue();
  if (backup != null) AppLogger.info('Backup', 'Automatic backup: ${backup.path}');

  // Optional online sync: a no-op unless an owner connected a server.
  ref.read(autoSyncProvider);

  AppLogger.info('App', 'Bootstrap complete in ${sw.elapsedMilliseconds}ms · ${cache.length} materials');
  if (kDebugMode) debugPrint('⏱ Bootstrap complete · ${cache.length} materials cached');
});
