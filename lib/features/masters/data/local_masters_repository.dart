import 'dart:convert';

import 'package:drift/drift.dart' hide Column;

import '../../../core/local/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../sales/data/models/material_dto.dart';
import 'masters_api_repository.dart';
import 'models/category_dto.dart';
import 'models/manufacturer_dto.dart';
import 'models/save_category_request.dart';
import 'models/save_manufacturer_request.dart';
import 'models/save_material_request.dart';
import 'models/save_supplier_request.dart';
import 'models/supplier_dto.dart';

class LocalMastersRepository {
  LocalMastersRepository(this._db, this._remote);

  final AppDatabase _db;
  final MastersApiRepository _remote;

  Future<List<CategoryDto>> getCategories() async {
    final cached = await _getCachedCategories();

    try {
      await syncPendingMasters();
      final remote = await _remote.getCategories();
      await _cacheCategories(remote);
      return await _getCachedCategories();
    } on ApiException catch (e) {
      if (cached.isNotEmpty && e.statusCode == null) return cached;
      if (cached.isNotEmpty && e.statusCode == 404) return cached;
      rethrow;
    }
  }

  Future<List<ManufacturerDto>> getManufacturers() async {
    final rows = await (_db.select(_db.cachedManufacturers)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
    return rows
        .map((row) => ManufacturerDto(name: row.name, description: row.description))
        .toList();
  }

  Future<ManufacturerDto> createManufacturer(SaveManufacturerRequest request) async {
    final name = request.name.trim();
    if (name.isEmpty) {
      throw const ApiException('Manufacturer name is required.');
    }

    final existing = await (_db.select(_db.cachedManufacturers)
          ..where((tbl) => tbl.name.lower().equals(name.toLowerCase())))
        .getSingleOrNull();
    if (existing != null) {
      throw const ApiException('Manufacturer already exists.');
    }

    final manufacturer = ManufacturerDto(
      name: name,
      description: request.description?.trim().isEmpty ?? true ? null : request.description?.trim(),
    );
    final now = DateTime.now().toUtc();
    await _db.into(_db.cachedManufacturers).insert(
          CachedManufacturersCompanion.insert(
            name: manufacturer.name,
            description: Value(manufacturer.description),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
          mode: InsertMode.insertOrReplace,
        );
    return manufacturer;
  }

  Future<ManufacturerDto> updateManufacturer(String previousName, SaveManufacturerRequest request) async {
    final nextName = request.name.trim();
    if (nextName.isEmpty) {
      throw const ApiException('Manufacturer name is required.');
    }

    final duplicate = await (_db.select(_db.cachedManufacturers)
          ..where((tbl) => tbl.name.lower().equals(nextName.toLowerCase())))
        .getSingleOrNull();
    if (duplicate != null && duplicate.name.toLowerCase() != previousName.toLowerCase()) {
      throw const ApiException('Another manufacturer already uses that name.');
    }

    final existing = await (_db.select(_db.cachedManufacturers)..where((tbl) => tbl.name.equals(previousName))).getSingleOrNull();
    final now = DateTime.now().toUtc();

    await _db.transaction(() async {
      if (previousName != nextName) {
        await (_db.delete(_db.cachedManufacturers)..where((tbl) => tbl.name.equals(previousName))).go();
        await (_db.update(_db.cachedMaterials)..where((tbl) => tbl.manufacturer.equals(previousName))).write(
          CachedMaterialsCompanion(
            manufacturer: Value(nextName),
            updatedAt: Value(now),
          ),
        );
      }
      await _db.into(_db.cachedManufacturers).insert(
            CachedManufacturersCompanion.insert(
              name: nextName,
              description: Value(request.description?.trim().isEmpty ?? true ? null : request.description?.trim()),
              createdAt: Value(existing?.createdAt ?? now),
              updatedAt: Value(now),
            ),
            mode: InsertMode.insertOrReplace,
          );
    });

    return ManufacturerDto(
      name: nextName,
      description: request.description?.trim().isEmpty ?? true ? null : request.description?.trim(),
    );
  }

  Future<List<CategoryDto>> _getCachedCategories() async {
    final pendingNames = await _pendingCategoryNames();
    final rows = await (_db.select(_db.cachedCategories)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
    return rows
        .map(
          (row) => CategoryDto(
            name: row.name,
            description: row.description,
            isPendingSync: pendingNames.contains(row.name.toLowerCase()),
          ),
        )
        .toList();
  }

  Future<CategoryDto> createCategory(SaveCategoryRequest request) async {
    final name = request.name.trim();
    if (name.isEmpty) {
      throw const ApiException('Category name is required.');
    }

    final existing = await (_db.select(_db.cachedCategories)
          ..where((tbl) => tbl.name.lower().equals(name.toLowerCase())))
        .getSingleOrNull();
    if (existing != null) {
      throw const ApiException('Category already exists.');
    }

    try {
      final created = await _remote.createCategory(
        SaveCategoryRequest(
          name: name,
          description: request.description?.trim().isEmpty ?? true ? null : request.description?.trim(),
        ),
      );
      await _upsertCategoryRecord(created, syncStatus: 'synced');
      return created;
    } on ApiException catch (e) {
      if (e.statusCode != null && e.statusCode != 404) rethrow;

      final category = CategoryDto(
        name: name,
        description: request.description?.trim().isEmpty ?? true ? null : request.description?.trim(),
        isPendingSync: true,
      );
      await _upsertCategoryRecord(category, syncStatus: 'pending_create');
      await _enqueueSync(
        entityType: 'category',
        entityId: category.name,
        operation: 'create',
        payload: SaveCategoryRequest(name: category.name, description: category.description).toJson(),
      );
      return category;
    }
  }

  Future<CategoryDto> updateCategory(String previousName, SaveCategoryRequest request) async {
    final nextName = request.name.trim();
    if (nextName.isEmpty) {
      throw const ApiException('Category name is required.');
    }

    final duplicate = await (_db.select(_db.cachedCategories)
          ..where((tbl) => tbl.name.lower().equals(nextName.toLowerCase())))
        .getSingleOrNull();
    if (duplicate != null && duplicate.name.toLowerCase() != previousName.toLowerCase()) {
      throw const ApiException('Another category already uses that name.');
    }

    final trimmedDescription = request.description?.trim().isEmpty ?? true ? null : request.description?.trim();
    try {
      final saved = await _remote.updateCategory(previousName, SaveCategoryRequest(name: nextName, description: trimmedDescription));
      await _db.transaction(() async {
        await _renameCategoryReferences(previousName: previousName, nextName: saved.name);
        await _upsertCategoryRecord(saved, syncStatus: 'synced');
      });
      return saved;
    } on ApiException catch (e) {
      if (e.statusCode != null && e.statusCode != 404) rethrow;

      final cached = await (_db.select(_db.cachedCategories)..where((tbl) => tbl.name.equals(previousName))).getSingleOrNull();
      final syncStatus = cached == null ? 'pending_create' : 'pending_update';
      final pending = CategoryDto(name: nextName, description: trimmedDescription, isPendingSync: true);

      await _db.transaction(() async {
        await _renameCategoryReferences(previousName: previousName, nextName: nextName);
        await _upsertCategoryRecord(
          pending,
          syncStatus: syncStatus,
          preserveCreatedAt: cached?.createdAt,
        );
        await _enqueueSync(
          entityType: 'category',
          entityId: nextName,
          operation: syncStatus == 'pending_create' ? 'create' : 'update',
          payload: SaveCategoryRequest(name: nextName, description: trimmedDescription).toJson(),
          previousEntityId: previousName == nextName ? null : previousName,
        );
      });
      return pending;
    }
  }

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
    await ensureManufacturerExists(request.manufacturer);
    await ensureCategoryExists(request.category);
    try {
      final created = (await _remote.createMaterial(request)).copyWith(manufacturer: request.manufacturer);
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
        manufacturer: request.manufacturer,
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
    await ensureManufacturerExists(request.manufacturer);
    await ensureCategoryExists(request.category);
    try {
      final updated = (await _remote.updateMaterial(id, request)).copyWith(manufacturer: request.manufacturer);
      await _upsertMaterial(updated, syncStatus: 'synced');
      return updated;
    } on ApiException catch (e) {
      if (e.statusCode != null) rethrow;

      final cached = await (_db.select(_db.cachedMaterials)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      final local = MaterialDto(
        id: id,
        barcode: request.barcode ?? cached?.barcode ?? id,
        name: request.name,
        manufacturer: request.manufacturer,
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
      manufacturer: row.manufacturer,
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
          case 'category':
            await _syncCategory(item);
            break;
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
            manufacturer: row.manufacturer,
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
    final existingRows = await (_db.select(_db.cachedMaterials)).get();
    final existingManufacturerById = {
      for (final row in existingRows) row.id: row.manufacturer,
    };

    await _db.batch((batch) {
      for (final material in materials) {
        if (pendingIds.contains(material.id)) continue;
        final manufacturer = material.manufacturer.isNotEmpty
            ? material.manufacturer
            : (existingManufacturerById[material.id]?.isNotEmpty ?? false)
                ? existingManufacturerById[material.id]!
                : _deriveManufacturerName(material.name);

        batch.insert(
          _db.cachedMaterials,
          CachedMaterialsCompanion.insert(
            id: material.id,
            barcode: material.barcode,
            name: material.name,
            manufacturer: Value(manufacturer),
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
    for (final material in materials) {
      await ensureManufacturerExists(
        material.manufacturer.isNotEmpty ? material.manufacturer : _deriveManufacturerName(material.name),
      );
      await ensureCategoryExists(material.category);
    }
  }

  Future<void> _cacheCategories(List<CategoryDto> categories) async {
    final pendingNames = await _pendingCategoryNames();
    final now = DateTime.now().toUtc();

    await _db.batch((batch) {
      for (final category in categories) {
        if (pendingNames.contains(category.name.toLowerCase())) continue;
        batch.insert(
          _db.cachedCategories,
          CachedCategoriesCompanion.insert(
            name: category.name,
            description: Value(category.description),
            createdAt: Value(now),
            updatedAt: Value(now),
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

  Future<Set<String>> _pendingCategoryNames() async {
    final queue = await (_db.select(_db.syncQueueItems)
          ..where((tbl) => tbl.entityType.equals('category') & tbl.status.isNotValue('failed')))
        .get();
    return queue.map((row) => row.entityId.toLowerCase()).toSet();
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
            manufacturer: Value(material.manufacturer),
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

  Future<void> ensureCategoryExists(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return;
    final existing = await (_db.select(_db.cachedCategories)..where((tbl) => tbl.name.lower().equals(name.toLowerCase()))).getSingleOrNull();
    if (existing != null) return;
    final category = CategoryDto(name: name, isPendingSync: true);
    await _upsertCategoryRecord(category, syncStatus: 'pending_create');
    await _enqueueSync(
      entityType: 'category',
      entityId: name,
      operation: 'create',
      payload: SaveCategoryRequest(name: name).toJson(),
    );
  }

  Future<void> ensureManufacturerExists(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return;
    final existing = await (_db.select(_db.cachedManufacturers)..where((tbl) => tbl.name.lower().equals(name.toLowerCase()))).getSingleOrNull();
    if (existing != null) return;
    final now = DateTime.now().toUtc();
    await _db.into(_db.cachedManufacturers).insert(
          CachedManufacturersCompanion.insert(
            name: name,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  String _deriveManufacturerName(String itemName) {
    final normalized = itemName.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return 'Unknown';
    final words = normalized.split(' ');
    if (words.length == 1) return words.first;
    const compounds = {
      'royal stag',
      'blenders pride',
      'magic moments',
      'old monk',
      'royal challenge',
      '100 pipers',
      'teacher\'s highland',
      'johnnie walker',
      'coca-cola',
      'coca-cola can',
    };
    final firstTwo = '${words[0]} ${words[1]}'.toLowerCase();
    if (compounds.contains(firstTwo)) {
      return '${words[0]} ${words[1]}';
    }
    return words.first;
  }

  Future<void> _upsertCategoryRecord(
    CategoryDto category, {
    required String syncStatus,
    DateTime? preserveCreatedAt,
  }) async {
    final now = DateTime.now().toUtc();
    await _db.into(_db.cachedCategories).insert(
          CachedCategoriesCompanion.insert(
            name: category.name,
            description: Value(category.description),
            createdAt: Value(preserveCreatedAt ?? now),
            updatedAt: Value(now),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> _enqueueSync({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    String? previousEntityId,
  }) async {
    if (previousEntityId != null) {
      await (_db.delete(_db.syncQueueItems)
            ..where((tbl) => tbl.entityType.equals(entityType) & tbl.entityId.equals(previousEntityId)))
          .go();
    }
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
      manufacturer: (payload['manufacturer'] as String?) ?? '',
      category: payload['category'] as String,
      packing: (payload['packing'] as String?) ?? '',
      saleRate: _asDouble(payload['saleRate']),
      taxPercent: _asDouble(payload['taxPercent']),
    );

    if (item.operation == 'create') {
      final created = await _remote.createMaterial(request);
      await _db.transaction(() async {
        await _upsertMaterial(created.copyWith(manufacturer: request.manufacturer), syncStatus: 'synced');
        await _clearQueueFor(item.entityType, item.entityId);
      });
      return;
    }

    final updated = await _remote.updateMaterial(item.entityId, request);
    await _db.transaction(() async {
      await _upsertMaterial(updated.copyWith(manufacturer: request.manufacturer), syncStatus: 'synced');
      await _clearQueueFor(item.entityType, item.entityId);
    });
  }

  Future<void> _syncCategory(SyncQueueItem item) async {
    final payload = _decodePayload(item.payload);
    final request = SaveCategoryRequest(
      name: payload['name'] as String,
      description: payload['description'] as String?,
    );

    try {
      if (item.operation == 'create') {
        final created = await _remote.createCategory(request);
        await _db.transaction(() async {
          if (item.entityId != created.name) {
            await _renameCategoryReferences(previousName: item.entityId, nextName: created.name);
            await (_db.delete(_db.cachedCategories)..where((tbl) => tbl.name.equals(item.entityId))).go();
          }
          await _upsertCategoryRecord(created, syncStatus: 'synced');
          await _clearQueueFor(item.entityType, item.entityId);
        });
        return;
      }

      final updated = await _remote.updateCategory(item.entityId, request);
      await _db.transaction(() async {
        if (item.entityId != updated.name) {
          await _renameCategoryReferences(previousName: item.entityId, nextName: updated.name);
          await (_db.delete(_db.cachedCategories)..where((tbl) => tbl.name.equals(item.entityId))).go();
        }
        await _upsertCategoryRecord(updated, syncStatus: 'synced');
        await _clearQueueFor(item.entityType, item.entityId);
      });
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        await _clearQueueFor(item.entityType, item.entityId);
        return;
      }
      rethrow;
    }
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

  Future<void> _renameCategoryReferences({
    required String previousName,
    required String nextName,
  }) async {
    if (previousName == nextName) return;

    await (_db.delete(_db.cachedCategories)..where((tbl) => tbl.name.equals(previousName))).go();
    await (_db.update(_db.cachedMaterials)..where((tbl) => tbl.category.equals(previousName))).write(
      CachedMaterialsCompanion(
        category: Value(nextName),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await (_db.update(_db.cachedInventoryStocks)..where((tbl) => tbl.category.equals(previousName))).write(
      CachedInventoryStocksCompanion(
        category: Value(nextName),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
