import 'dart:convert';

import 'package:drift/drift.dart' hide Column;

import '../../../core/local/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../sales/data/models/material_dto.dart';
import 'masters_api_repository.dart';
import 'models/save_material_request.dart';
import 'models/save_supplier_request.dart';
import 'models/supplier_dto.dart';

class LocalMastersRepository {
  LocalMastersRepository(this._db, this._remote);

  final AppDatabase _db;
  final MastersApiRepository _remote;

  Future<List<SupplierDto>> getSuppliers() async {
    final cached = await _getCachedSuppliers();

    try {
      await syncPendingMasters();
      final remote = await _remote.getSuppliers();
      await _cacheSuppliers(remote);
      return await _getCachedSuppliers();
    } on ApiException catch (e) {
      if (cached.isNotEmpty && e.statusCode == null) return cached;
      rethrow;
    }
  }

  Future<SupplierDto> createSupplier(SaveSupplierRequest request) async {
    try {
      final created = await _remote.createSupplier(request);
      await _upsertSupplier(created, syncStatus: 'synced');
      return created;
    } on ApiException catch (e) {
      if (e.statusCode != null) rethrow;

      final local = SupplierDto(
        id: 'local-supplier-${DateTime.now().microsecondsSinceEpoch}',
        name: request.name,
        address: request.address,
        contactNo: request.contactNo,
        email: request.email,
        vatNo: request.vatNo,
        bankDetails: request.bankDetails,
        disPercent: request.disPercent,
        openingBalance: request.openingBalance,
        balanceType: request.balanceType,
        isPendingSync: true,
      );

      await _upsertSupplier(local, syncStatus: 'pending_create');
      await _enqueueSync(
        entityType: 'supplier',
        entityId: local.id,
        operation: 'create',
        payload: request.toJson(),
      );
      return local;
    }
  }

  Future<SupplierDto> updateSupplier(String id, SaveSupplierRequest request) async {
    try {
      final updated = await _remote.updateSupplier(id, request);
      await _upsertSupplier(updated, syncStatus: 'synced');
      return updated;
    } on ApiException catch (e) {
      if (e.statusCode != null) rethrow;

      final cached = await (_db.select(_db.cachedSuppliers)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

      final local = SupplierDto(
        id: id,
        name: request.name,
        address: request.address,
        contactNo: request.contactNo,
        email: request.email,
        vatNo: request.vatNo,
        bankDetails: request.bankDetails,
        disPercent: request.disPercent,
        openingBalance: request.openingBalance,
        balanceType: request.balanceType,
        isPendingSync: true,
      );

      final nextStatus = cached?.syncStatus == 'pending_create' ? 'pending_create' : 'pending_update';
      await _upsertSupplier(local, syncStatus: nextStatus, preserveCreatedAt: cached?.createdAt);
      await _enqueueSync(
        entityType: 'supplier',
        entityId: id,
        operation: nextStatus == 'pending_create' ? 'create' : 'update',
        payload: request.toJson(),
      );
      return local;
    }
  }

  Future<List<MaterialDto>> getMaterials() async {
    final cached = await _getCachedMaterials();

    try {
      await syncPendingMasters();
      final remote = await _remote.getMaterials();
      await _cacheMaterials(remote);
      return await _getCachedMaterials();
    } on ApiException catch (e) {
      if (cached.isNotEmpty && e.statusCode == null) return cached;
      rethrow;
    }
  }

  Future<MaterialDto> createMaterial(SaveMaterialRequest request) async {
    try {
      final created = await _remote.createMaterial(request);
      await _upsertMaterial(created, syncStatus: 'synced');
      return created;
    } on ApiException catch (e) {
      if (e.statusCode != null) rethrow;

      final existing = await (_db.select(_db.cachedMaterials)..where((tbl) => tbl.id.equals(request.id))).getSingleOrNull();
      if (existing != null) {
        throw const ApiException('Material code already exists in local cache.');
      }

      final local = MaterialDto(
        id: request.id,
        barcode: request.barcode ?? request.id,
        name: request.name,
        category: request.category,
        packing: request.packing,
        saleRate: request.saleRate,
        taxPercent: request.taxPercent,
        stockQty: 0,
        isPendingSync: true,
      );

      await _upsertMaterial(local, syncStatus: 'pending_create');
      await _enqueueSync(
        entityType: 'material',
        entityId: local.id,
        operation: 'create',
        payload: request.toJson(),
      );
      return local;
    }
  }

  Future<MaterialDto> updateMaterial(String id, SaveMaterialRequest request) async {
    try {
      final updated = await _remote.updateMaterial(id, request);
      await _upsertMaterial(updated, syncStatus: 'synced');
      return updated;
    } on ApiException catch (e) {
      if (e.statusCode != null) rethrow;

      final cached = await (_db.select(_db.cachedMaterials)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      final local = MaterialDto(
        id: id,
        barcode: request.barcode ?? cached?.barcode ?? id,
        name: request.name,
        category: request.category,
        packing: request.packing,
        saleRate: request.saleRate,
        taxPercent: request.taxPercent,
        stockQty: cached?.stockQty ?? 0,
        isPendingSync: true,
      );

      final nextStatus = cached?.syncStatus == 'pending_create' ? 'pending_create' : 'pending_update';
      await _upsertMaterial(local, syncStatus: nextStatus, preserveCreatedAt: cached?.createdAt);
      await _enqueueSync(
        entityType: 'material',
        entityId: id,
        operation: nextStatus == 'pending_create' ? 'create' : 'update',
        payload: request.toJson(),
      );
      return local;
    }
  }

  Future<MaterialDto?> getMaterialByBarcode(String barcode) async {
    try {
      await syncPendingMasters();
      final remote = await _remote.getMaterials();
      await _cacheMaterials(remote);
    } on ApiException {
      // Fall back to local cache below.
    }

    final row = await (_db.select(_db.cachedMaterials)
          ..where((tbl) => tbl.barcode.equals(barcode) | tbl.id.equals(barcode)))
        .getSingleOrNull();
    if (row == null) return null;

    return MaterialDto(
      id: row.id,
      barcode: row.barcode,
      name: row.name,
      category: row.category,
      packing: row.packing,
      saleRate: row.saleRate,
      taxPercent: row.taxPercent,
      stockQty: row.stockQty,
      isPendingSync: row.syncStatus != 'synced',
    );
  }

  Future<int> getPendingSyncCount({Set<String>? entityTypes}) async {
    final countExp = _db.syncQueueItems.id.count();
    final query = _db.selectOnly(_db.syncQueueItems);
    if (entityTypes != null && entityTypes.isNotEmpty) {
      query.where(_db.syncQueueItems.entityType.isIn(entityTypes));
    }
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Stream<int> watchPendingSyncCount({Set<String>? entityTypes}) {
    final countExp = _db.syncQueueItems.id.count();
    final query = _db.selectOnly(_db.syncQueueItems);
    if (entityTypes != null && entityTypes.isNotEmpty) {
      query.where(_db.syncQueueItems.entityType.isIn(entityTypes));
    }
    query.addColumns([countExp]);
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<void> syncPendingMasters() async {
    final rows = await (_db.select(_db.syncQueueItems)
          ..where((tbl) => tbl.status.equals('pending'))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt), (tbl) => OrderingTerm.asc(tbl.id)]))
        .get();

    if (rows.isEmpty) return;

    final latestByEntity = <String, SyncQueueItem>{};
    for (final row in rows) {
      latestByEntity['${row.entityType}:${row.entityId}'] = row;
    }

    for (final item in latestByEntity.values) {
      try {
        await _markQueueProcessing(item.entityType, item.entityId);

        switch (item.entityType) {
          case 'supplier':
            await _syncSupplier(item);
            break;
          case 'material':
            await _syncMaterial(item);
            break;
        }
      } on ApiException catch (e) {
        if (e.statusCode == null) {
          await _markQueuePending(
            item.entityType,
            item.entityId,
            lastError: e.message,
          );
          rethrow;
        }

        await _markQueueFailed(
          item.entityType,
          item.entityId,
          lastError: e.message,
        );
      }
    }
  }

  Future<List<SupplierDto>> _getCachedSuppliers() async {
    final rows = await (_db.select(_db.cachedSuppliers)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
    return rows
        .map(
          (row) => SupplierDto(
            id: row.id,
            name: row.name,
            address: row.address,
            contactNo: row.contactNo,
            email: row.email,
            vatNo: row.vatNo,
            bankDetails: row.bankDetails,
            disPercent: row.disPercent,
            openingBalance: row.openingBalance,
            balanceType: row.balanceType,
            isPendingSync: row.syncStatus != 'synced',
          ),
        )
        .toList();
  }

  Future<List<MaterialDto>> _getCachedMaterials() async {
    final rows = await (_db.select(_db.cachedMaterials)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
    return rows
        .map(
          (row) => MaterialDto(
            id: row.id,
            barcode: row.barcode,
            name: row.name,
            category: row.category,
            packing: row.packing,
            saleRate: row.saleRate,
            taxPercent: row.taxPercent,
            stockQty: row.stockQty,
            isPendingSync: row.syncStatus != 'synced',
          ),
        )
        .toList();
  }

  Future<void> _cacheSuppliers(List<SupplierDto> suppliers) async {
    final pendingIds = await _pendingSupplierIds();

    await _db.batch((batch) {
      for (final supplier in suppliers) {
        if (pendingIds.contains(supplier.id)) continue;

        batch.insert(
          _db.cachedSuppliers,
          CachedSuppliersCompanion.insert(
            id: supplier.id,
            name: supplier.name,
            address: Value(supplier.address),
            contactNo: Value(supplier.contactNo),
            email: Value(supplier.email),
            vatNo: Value(supplier.vatNo),
            bankDetails: Value(supplier.bankDetails),
            disPercent: Value(supplier.disPercent),
            openingBalance: Value(supplier.openingBalance),
            balanceType: Value(supplier.balanceType),
            syncStatus: const Value('synced'),
            updatedAt: Value(DateTime.now().toUtc()),
            lastSyncedAt: Value(DateTime.now().toUtc()),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _cacheMaterials(List<MaterialDto> materials) async {
    final pendingIds = await _pendingMaterialIds();

    await _db.batch((batch) {
      for (final material in materials) {
        if (pendingIds.contains(material.id)) continue;

        batch.insert(
          _db.cachedMaterials,
          CachedMaterialsCompanion.insert(
            id: material.id,
            barcode: material.barcode,
            name: material.name,
            category: material.category,
            packing: material.packing,
            saleRate: material.saleRate,
            taxPercent: material.taxPercent,
            stockQty: Value(material.stockQty),
            syncStatus: const Value('synced'),
            updatedAt: Value(DateTime.now().toUtc()),
            lastSyncedAt: Value(DateTime.now().toUtc()),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<Set<String>> _pendingSupplierIds() async {
    final rows = await (_db.select(_db.cachedSuppliers)
          ..where((tbl) => tbl.syncStatus.isNotValue('synced')))
        .get();
    return rows.map((row) => row.id).toSet();
  }

  Future<Set<String>> _pendingMaterialIds() async {
    final rows = await (_db.select(_db.cachedMaterials)
          ..where((tbl) => tbl.syncStatus.isNotValue('synced')))
        .get();
    return rows.map((row) => row.id).toSet();
  }

  Future<void> _upsertSupplier(
    SupplierDto supplier, {
    required String syncStatus,
    DateTime? preserveCreatedAt,
  }) async {
    final now = DateTime.now().toUtc();
    await _db.into(_db.cachedSuppliers).insert(
          CachedSuppliersCompanion.insert(
            id: supplier.id,
            name: supplier.name,
            address: Value(supplier.address),
            contactNo: Value(supplier.contactNo),
            email: Value(supplier.email),
            vatNo: Value(supplier.vatNo),
            bankDetails: Value(supplier.bankDetails),
            disPercent: Value(supplier.disPercent),
            openingBalance: Value(supplier.openingBalance),
            balanceType: Value(supplier.balanceType),
            syncStatus: Value(syncStatus),
            createdAt: Value(preserveCreatedAt ?? now),
            updatedAt: Value(now),
            lastSyncedAt: syncStatus == 'synced' ? Value(now) : const Value.absent(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> _upsertMaterial(
    MaterialDto material, {
    required String syncStatus,
    DateTime? preserveCreatedAt,
  }) async {
    final now = DateTime.now().toUtc();
    await _db.into(_db.cachedMaterials).insert(
          CachedMaterialsCompanion.insert(
            id: material.id,
            barcode: material.barcode,
            name: material.name,
            category: material.category,
            packing: material.packing,
            saleRate: material.saleRate,
            taxPercent: material.taxPercent,
            stockQty: Value(material.stockQty),
            syncStatus: Value(syncStatus),
            createdAt: Value(preserveCreatedAt ?? now),
            updatedAt: Value(now),
            lastSyncedAt: syncStatus == 'synced' ? Value(now) : const Value.absent(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> _enqueueSync({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await _db.into(_db.syncQueueItems).insert(
          SyncQueueItemsCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payload: jsonEncode(payload),
            status: const Value('pending'),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<void> _syncSupplier(SyncQueueItem item) async {
    final payload = _decodePayload(item.payload);
    final request = SaveSupplierRequest(
      name: payload['name'] as String,
      address: payload['address'] as String?,
      contactNo: payload['contactNo'] as String?,
      email: payload['email'] as String?,
      vatNo: payload['vatNo'] as String?,
      bankDetails: payload['bankDetails'] as String?,
      disPercent: _asDouble(payload['disPercent']),
      openingBalance: _asDouble(payload['openingBalance']),
      balanceType: payload['balanceType'] as String,
    );

    if (item.operation == 'create') {
      final created = await _remote.createSupplier(request);
      await _db.transaction(() async {
        await _rebindSupplierReferences(oldId: item.entityId, newId: created.id);
        await (_db.delete(_db.cachedSuppliers)..where((tbl) => tbl.id.equals(item.entityId))).go();
        await _upsertSupplier(created, syncStatus: 'synced');
        await _clearQueueFor(item.entityType, item.entityId);
      });
      return;
    }

    final updated = await _remote.updateSupplier(item.entityId, request);
    await _db.transaction(() async {
      await _upsertSupplier(updated, syncStatus: 'synced');
      await _clearQueueFor(item.entityType, item.entityId);
    });
  }

  Future<void> _syncMaterial(SyncQueueItem item) async {
    final payload = _decodePayload(item.payload);
    final request = SaveMaterialRequest(
      id: payload['id'] as String,
      barcode: payload['barcode'] as String?,
      name: payload['name'] as String,
      category: payload['category'] as String,
      packing: (payload['packing'] as String?) ?? '',
      saleRate: _asDouble(payload['saleRate']),
      taxPercent: _asDouble(payload['taxPercent']),
    );

    if (item.operation == 'create') {
      final created = await _remote.createMaterial(request);
      await _db.transaction(() async {
        await _upsertMaterial(created, syncStatus: 'synced');
        await _clearQueueFor(item.entityType, item.entityId);
      });
      return;
    }

    final updated = await _remote.updateMaterial(item.entityId, request);
    await _db.transaction(() async {
      await _upsertMaterial(updated, syncStatus: 'synced');
      await _clearQueueFor(item.entityType, item.entityId);
    });
  }

  Future<void> _markQueueProcessing(String entityType, String entityId) async {
    await (_db.update(_db.syncQueueItems)
          ..where((tbl) => tbl.entityType.equals(entityType) & tbl.entityId.equals(entityId)))
        .write(
      SyncQueueItemsCompanion(
        status: const Value('processing'),
        lastError: const Value(null),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> _markQueuePending(
    String entityType,
    String entityId, {
    required String lastError,
  }) async {
    await (_db.update(_db.syncQueueItems)
          ..where((tbl) => tbl.entityType.equals(entityType) & tbl.entityId.equals(entityId)))
        .write(
      SyncQueueItemsCompanion(
        status: const Value('pending'),
        lastError: Value(lastError),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> _markQueueFailed(
    String entityType,
    String entityId, {
    required String lastError,
  }) async {
    await (_db.update(_db.syncQueueItems)
          ..where((tbl) => tbl.entityType.equals(entityType) & tbl.entityId.equals(entityId)))
        .write(
      SyncQueueItemsCompanion(
        status: const Value('failed'),
        lastError: Value(lastError),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> _clearQueueFor(String entityType, String entityId) async {
    await (_db.delete(_db.syncQueueItems)
          ..where((tbl) => tbl.entityType.equals(entityType) & tbl.entityId.equals(entityId)))
        .go();
  }

  Future<void> _rebindSupplierReferences({
    required String oldId,
    required String newId,
  }) async {
    final purchaseRows = await (_db.select(_db.syncQueueItems)
          ..where((tbl) => tbl.entityType.equals('purchase') & tbl.status.equals('pending')))
        .get();

    for (final row in purchaseRows) {
      final payload = _decodePayload(row.payload);
      if (payload['supplierId'] != oldId) continue;
      payload['supplierId'] = newId;

      await (_db.update(_db.syncQueueItems)..where((tbl) => tbl.id.equals(row.id))).write(
        SyncQueueItemsCompanion(
          payload: Value(jsonEncode(payload)),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
    }
  }

  Map<String, dynamic> _decodePayload(String raw) => jsonDecode(raw) as Map<String, dynamic>;

  double _asDouble(Object? value) => (value as num).toDouble();
}
