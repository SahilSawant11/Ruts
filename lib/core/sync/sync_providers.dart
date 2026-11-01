import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/masters/data/masters_providers.dart';
import '../logging/app_logger.dart';
import 'online_sync_service.dart';

final onlineSyncServiceProvider = Provider<OnlineSyncService>((ref) => OnlineSyncService(ref.watch(appDatabaseProvider)));

/// Refreshable connection status for the Settings screen.
final onlineSyncStatusProvider = FutureProvider<({bool connected, String? url, String? store, DateTime? lastAt, String? lastResult})>(
  (ref) async {
    final s = ref.watch(onlineSyncServiceProvider);
    return (
      connected: await s.isConnected(),
      url: await s.serverUrl(),
      store: await s.storeName(),
      lastAt: await s.lastSyncAt(),
      lastResult: await s.lastResult(),
    );
  },
);

/// Background sync every few minutes while a server is connected. Does
/// nothing (and costs nothing) for offline-only stores.
final autoSyncProvider = Provider<Timer>((ref) {
  final service = ref.watch(onlineSyncServiceProvider);
  Future<void> tick() async {
    if (!await service.isConnected()) return;
    final r = await service.syncNow();
    AppLogger.info('Sync', 'Auto sync: $r');
    ref.invalidate(onlineSyncStatusProvider);
  }

  final timer = Timer.periodic(const Duration(minutes: 3), (_) => tick());
  unawaited(Future<void>.delayed(const Duration(seconds: 20), tick));
  ref.onDispose(timer.cancel);
  return timer;
});
