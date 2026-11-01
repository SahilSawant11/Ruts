import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/masters/data/masters_providers.dart';
import '../../features/settings/data/settings_providers.dart';
import '../auth/auth_controller.dart';
import '../logging/app_logger.dart';
import 'material_lookup_cache.dart';

final appBootstrapProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final sw = Stopwatch()..start();

  // PRAGMAs are set in AppDatabase.migration.beforeOpen (per-connection).

  // ── Seed lookup data once (demo transactions only in demo builds) ──
  await db.ensureStarterData();
  await db.deviceId();
  await ref.read(authRepositoryProvider).ensureDefaultUsers();

  // ── Warm the in-memory material lookup cache ──────────────────────
  final cache = await MaterialLookupCache.load(db);
  ref.read(materialLookupCacheProvider.notifier).state = cache;

  // ── Daily automatic backup (never blocks or fails startup) ─────────
  final backup = await ref.read(backupServiceProvider).autoBackupIfDue();
  if (backup != null) AppLogger.info('Backup', 'Automatic backup: ${backup.path}');

  AppLogger.info('App', 'Bootstrap complete in ${sw.elapsedMilliseconds}ms · ${cache.length} materials');
  if (kDebugMode) debugPrint('⏱ Bootstrap complete · ${cache.length} materials cached');
});
