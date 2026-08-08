import 'dart:convert';

import 'package:drift/drift.dart' hide Column;

import '../../../core/local/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../masters/data/local_masters_repository.dart';
import 'models/inventory_item_dto.dart';
import 'models/inventory_overview_item.dart';
import 'inventory_providers.dart';

class LocalInventoryRepository {
  LocalInventoryRepository(this._db, this._remote, this._masters);

  final AppDatabase _db;
  final InventoryApiRepository _remote;
  final LocalMastersRepository _masters;

  Future<List<InventoryItemDto>> getInventory() async {
    try {
      await _masters.syncPendingMasters();
      final remote = await _remote.getInventory();
      await _cacheInventory(remote);
    } on ApiException {
      // Fall back to cached snapshot below.
    }

    return _buildLocalInventoryList();
  }

  Future<List<InventoryOverviewItem>> getInventoryOverview() async {
    final materials = await _masters.getMaterials();
    final stock = await getInventory();
    final stockByMaterial = {for (final s in stock) s.materialId: s};

    return materials.map((m) {
      final s = stockByMaterial[m.id];
      return InventoryOverviewItem(
        materialId: m.id,
        barcode: m.barcode,
        name: m.name,
        category: m.category,
        qtyOnHand: s?.qtyOnHand ?? 0,
        reorderLevel: s?.reorderLevel ?? 10,
      );
    }).toList();
  }

  Future<void> _cacheInventory(List<InventoryItemDto> items) async {
    await _db.batch((batch) {
      for (final item in items) {
        batch.insert(
          _db.cachedInventoryStocks,
          CachedInventoryStocksCompanion.insert(
            materialId: item.materialId,
            barcode: item.barcode,
            name: item.name,
            category: item.category,
            qtyOnHand: item.qtyOnHand,
            reorderLevel: Value(item.reorderLevel),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<InventoryItemDto>> _buildLocalInventoryList() async {
    final snapshot = await (_db.select(_db.cachedInventoryStocks)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
    final materials = await _masters.getMaterials();
    final materialById = {for (final m in materials) m.id: m};
    final qtyByMaterial = <String, int>{
      for (final row in snapshot) row.materialId: row.qtyOnHand,
    };
    final reorderByMaterial = <String, int>{
      for (final row in snapshot) row.materialId: row.reorderLevel,
    };

    await _applyPendingPurchaseDeltas(qtyByMaterial);
    await _applyPendingSaleDeltas(qtyByMaterial);

    final allMaterialIds = {
      ...materialById.keys,
      ...qtyByMaterial.keys,
    }.toList()
      ..sort((a, b) {
        final aName = materialById[a]?.name ?? a;
        final bName = materialById[b]?.name ?? b;
        return aName.compareTo(bName);
      });

    return allMaterialIds.map((materialId) {
      final material = materialById[materialId];
      final barcode = material?.barcode ?? materialId;
      final name = material?.name ?? materialId;
      final category = material?.category ?? 'Unknown';

      return InventoryItemDto(
        materialId: materialId,
        barcode: barcode,
        name: name,
        category: category,
        qtyOnHand: qtyByMaterial[materialId] ?? 0,
        reorderLevel: reorderByMaterial[materialId] ?? 10,
      );
    }).toList();
  }

  Future<void> _applyPendingPurchaseDeltas(Map<String, int> qtyByMaterial) async {
    final rows = await (_db.select(_db.syncQueueItems)
          ..where((tbl) => tbl.entityType.equals('purchase') & tbl.status.isNotValue('failed')))
        .get();

    for (final row in rows) {
      final payload = jsonDecode(row.payload) as Map<String, dynamic>;
      final lineItems = payload['lineItems'] as List<dynamic>? ?? const [];
      for (final item in lineItems) {
        final materialId = (item as Map<String, dynamic>)['materialId'] as String;
        final qty = item['qty'] as int;
        qtyByMaterial[materialId] = (qtyByMaterial[materialId] ?? 0) + qty;
      }
    }
  }

  Future<void> _applyPendingSaleDeltas(Map<String, int> qtyByMaterial) async {
    final rows = await (_db.select(_db.syncQueueItems)
          ..where((tbl) => tbl.entityType.equals('sale') & tbl.status.isNotValue('failed')))
        .get();

    for (final row in rows) {
      final payload = jsonDecode(row.payload) as Map<String, dynamic>;
      final lineItems = payload['lineItems'] as List<dynamic>? ?? const [];
      for (final item in lineItems) {
        final map = item as Map<String, dynamic>;
        final materialId = map['materialId'] as String?;
        if (materialId == null) continue;
        final qty = map['quantity'] as int;
        qtyByMaterial[materialId] = (qtyByMaterial[materialId] ?? 0) - qty;
      }
    }
  }
}
