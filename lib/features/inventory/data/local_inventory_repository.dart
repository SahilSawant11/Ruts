import 'package:drift/drift.dart' hide Column;

import '../../../core/config/app_config.dart';
import '../../../core/local/app_database.dart';
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
    if (!AppConfig.offlineOnly) {
      try {
        await _masters.syncPendingMasters();
        final remote = await _remote.getInventory();
        await _cacheInventory(remote);
      } catch (_) {
        // Fall back to cached snapshot below.
      }
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
        manufacturer: m.manufacturer,
        category: m.category,
        packing: m.packing,
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

    // Stock levels are real-time: sale/purchase transactions update
    // cachedInventoryStocks in the same transaction as the bill.
    // No delta scanning needed.

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
      final packing = material?.packing ?? '';

      return InventoryItemDto(
        materialId: materialId,
        barcode: barcode,
        name: name,
        category: category,
        packing: packing,
        qtyOnHand: qtyByMaterial[materialId] ?? 0,
        reorderLevel: reorderByMaterial[materialId] ?? 10,
      );
    }).toList();
  }
}
