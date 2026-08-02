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
      final remote = await _remote.getSuppliers();
      await _cacheSuppliers(remote);
      return remote;
    } on ApiException {
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<SupplierDto> createSupplier(SaveSupplierRequest request) async {
    final created = await _remote.createSupplier(request);
    await _upsertSupplier(created);
    return created;
  }

  Future<SupplierDto> updateSupplier(String id, SaveSupplierRequest request) async {
    final updated = await _remote.updateSupplier(id, request);
    await _upsertSupplier(updated);
    return updated;
  }

  Future<List<MaterialDto>> getMaterials() async {
    final cached = await _getCachedMaterials();

    try {
      final remote = await _remote.getMaterials();
      await _cacheMaterials(remote);
      return remote;
    } on ApiException {
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<MaterialDto> createMaterial(SaveMaterialRequest request) async {
    final created = await _remote.createMaterial(request);
    await _upsertMaterial(created);
    return created;
  }

  Future<MaterialDto> updateMaterial(String id, SaveMaterialRequest request) async {
    final updated = await _remote.updateMaterial(id, request);
    await _upsertMaterial(updated);
    return updated;
  }

  Future<List<SupplierDto>> _getCachedSuppliers() async {
    final rows = await _db.select(_db.cachedSuppliers).get();
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
          ),
        )
        .toList();
  }

  Future<List<MaterialDto>> _getCachedMaterials() async {
    final rows = await _db.select(_db.cachedMaterials).get();
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
          ),
        )
        .toList();
  }

  Future<void> _cacheSuppliers(List<SupplierDto> suppliers) async {
    await _db.batch((batch) {
      for (final supplier in suppliers) {
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
    await _db.batch((batch) {
      for (final material in materials) {
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

  Future<void> _upsertSupplier(SupplierDto supplier) async {
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
            syncStatus: const Value('synced'),
            updatedAt: Value(DateTime.now().toUtc()),
            lastSyncedAt: Value(DateTime.now().toUtc()),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> _upsertMaterial(MaterialDto material) async {
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
            syncStatus: const Value('synced'),
            updatedAt: Value(DateTime.now().toUtc()),
            lastSyncedAt: Value(DateTime.now().toUtc()),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }
}
