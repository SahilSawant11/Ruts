import 'dart:async';

import 'package:drift/drift.dart' hide Column;

import '../../../core/local/app_database.dart';
import '../../masters/data/local_masters_repository.dart';
import '../../purchase/data/local_purchase_repository.dart';
import '../../sales/data/local_sales_repository.dart';

class SyncOverview {
  const SyncOverview({
    required this.total,
    required this.pending,
    required this.processing,
    required this.failed,
    required this.byEntityType,
    this.lastActivityAt,
  });

  final int total;
  final int pending;
  final int processing;
  final int failed;
  final Map<String, int> byEntityType;
  final DateTime? lastActivityAt;

  bool get isClean => total == 0;
}

class SyncRepository {
  SyncRepository(this._db, this._masters, this._purchase, this._sales);

  final AppDatabase _db;
  final LocalMastersRepository _masters;
  final LocalPurchaseRepository _purchase;
  final LocalSalesRepository _sales;

  Stream<SyncOverview> watchOverview() {
    return (_db.select(_db.syncQueueItems)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt), (tbl) => OrderingTerm.desc(tbl.id)]))
        .watch()
        .map(_buildOverview);
  }

  Stream<List<SyncQueueItem>> watchQueueItems() {
    return (_db.select(_db.syncQueueItems)
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.status),
            (tbl) => OrderingTerm.desc(tbl.updatedAt),
            (tbl) => OrderingTerm.desc(tbl.id),
          ]))
        .watch();
  }

  Future<void> syncNow() async {
    await _masters.syncPendingMasters();
    await _purchase.syncPendingPurchases();
    await _sales.syncPendingSales();
  }

  SyncOverview _buildOverview(List<SyncQueueItem> items) {
    final byEntity = <String, int>{};
    int pending = 0;
    int processing = 0;
    int failed = 0;
    DateTime? lastActivityAt;

    for (final item in items) {
      byEntity[item.entityType] = (byEntity[item.entityType] ?? 0) + 1;
      if (item.status == 'pending') pending++;
      if (item.status == 'processing') processing++;
      if (item.status == 'failed') failed++;
      if (lastActivityAt == null || item.updatedAt.isAfter(lastActivityAt)) {
        lastActivityAt = item.updatedAt;
      }
    }

    return SyncOverview(
      total: items.length,
      pending: pending,
      processing: processing,
      failed: failed,
      byEntityType: byEntity,
      lastActivityAt: lastActivityAt,
    );
  }
}
