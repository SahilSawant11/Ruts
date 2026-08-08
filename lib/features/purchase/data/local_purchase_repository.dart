import 'dart:convert';

import 'package:drift/drift.dart' hide Column;

import '../../../core/local/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../masters/data/local_masters_repository.dart';
import '../../masters/data/models/supplier_dto.dart';
import '../../sales/data/models/material_dto.dart';
import 'models/create_purchase_request.dart';
import 'purchase_api_repository.dart';

class LocalPurchaseRepository {
  LocalPurchaseRepository(this._db, this._remote, this._masters);

  final AppDatabase _db;
  final PurchaseApiRepository _remote;
  final LocalMastersRepository _masters;

  Future<List<SupplierDto>> getSuppliers() async {
    try {
      await syncPendingPurchases();
    } on ApiException {
      // Keep supplier dropdown available from local cache below.
    }
    return _masters.getSuppliers();
  }

  Future<MaterialDto?> getMaterialByBarcode(String barcode) async {
    try {
      await syncPendingPurchases();
    } on ApiException {
      // Keep material lookup available from local cache below.
    }
    return _masters.getMaterialByBarcode(barcode);
  }

  Stream<int> watchPendingPurchaseSyncCount() {
    return _masters.watchPendingSyncCount(entityTypes: {'purchase'});
  }

  Future<void> syncPendingPurchases() async {
    await _masters.syncPendingMasters();

    final rows = await (_db.select(_db.syncQueueItems)
          ..where((tbl) => tbl.entityType.equals('purchase') & tbl.status.equals('pending'))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt), (tbl) => OrderingTerm.asc(tbl.id)]))
        .get();

    for (final row in rows) {
      try {
        await (_db.update(_db.syncQueueItems)..where((tbl) => tbl.id.equals(row.id))).write(
          SyncQueueItemsCompanion(
            status: const Value('processing'),
            lastError: const Value(null),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );

        final request = _decodeRequest(row.payload);
        final syncedRequest = await _resolveDependencies(request);
        await _remote.createPurchase(syncedRequest);

        await (_db.delete(_db.syncQueueItems)..where((tbl) => tbl.id.equals(row.id))).go();
      } on ApiException catch (e) {
        final nextStatus = e.statusCode == null ? 'pending' : 'failed';
        await (_db.update(_db.syncQueueItems)..where((tbl) => tbl.id.equals(row.id))).write(
          SyncQueueItemsCompanion(
            status: Value(nextStatus),
            lastError: Value(e.message),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
        if (e.statusCode == null) rethrow;
      }
    }
  }

  Future<CreatePurchaseResult> createPurchase(CreatePurchaseRequest request) async {
    try {
      await syncPendingPurchases();
      final syncedRequest = await _resolveDependencies(request);
      return await _remote.createPurchase(syncedRequest);
    } on ApiException catch (e) {
      if (e.statusCode != null) rethrow;

      final localId = 'local-purchase-${DateTime.now().microsecondsSinceEpoch}';
      await _db.into(_db.syncQueueItems).insert(
            SyncQueueItemsCompanion.insert(
              entityType: 'purchase',
              entityId: localId,
              operation: 'create',
              payload: jsonEncode(request.toJson()),
              status: const Value('pending'),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );

      return CreatePurchaseResult(
        id: localId,
        billNo: request.billNo ?? 'Offline Queue',
        lineItemCount: request.lineItems.length,
        isPendingSync: true,
      );
    }
  }

  Future<CreatePurchaseRequest> _resolveDependencies(CreatePurchaseRequest request) async {
    final supplierId = await _resolveSupplierId(request.supplierId);

    final lineItems = <CreatePurchaseLineItemRequest>[];
    for (final item in request.lineItems) {
      final materialId = await _resolveMaterialId(item.materialId);
      lineItems.add(
        CreatePurchaseLineItemRequest(
          materialId: materialId,
          batchNo: item.batchNo,
          packing: item.packing,
          qty: item.qty,
          rate: item.rate,
          disPercent: item.disPercent,
          disAmount: item.disAmount,
          taxPercent: item.taxPercent,
          taxAmount: item.taxAmount,
          amount: item.amount,
        ),
      );
    }

    return CreatePurchaseRequest(
      supplierId: supplierId,
      billNo: request.billNo,
      challanNo: request.challanNo,
      noteNo: request.noteNo,
      payMode: request.payMode,
      tpNo: request.tpNo,
      tpDate: request.tpDate,
      stNo: request.stNo,
      discount: request.discount,
      vat: request.vat,
      stamp: request.stamp,
      tcs: request.tcs,
      loadingFreight: request.loadingFreight,
      netAmount: request.netAmount,
      totalAmount: request.totalAmount,
      lineItems: lineItems,
    );
  }

  Future<String> _resolveSupplierId(String id) async {
    final supplier = await (_db.select(_db.cachedSuppliers)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (supplier == null) return id;
    if (supplier.syncStatus == 'synced') return supplier.id;

    throw const ApiException('A selected supplier is still pending sync. Reconnect and sync masters first.');
  }

  Future<String> _resolveMaterialId(String id) async {
    final material = await (_db.select(_db.cachedMaterials)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (material == null) return id;
    if (material.syncStatus == 'synced' || material.syncStatus == 'pending_create') return material.id;

    throw const ApiException('A selected material is not ready to sync yet.');
  }

  CreatePurchaseRequest _decodeRequest(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final items = (json['lineItems'] as List<dynamic>)
        .map(
          (item) => CreatePurchaseLineItemRequest(
            materialId: item['materialId'] as String,
            batchNo: item['batchNo'] as String,
            packing: item['packing'] as String?,
            qty: item['qty'] as int,
            rate: (item['rate'] as num).toDouble(),
            disPercent: (item['disPercent'] as num).toDouble(),
            disAmount: (item['disAmount'] as num).toDouble(),
            taxPercent: (item['taxPercent'] as num).toDouble(),
            taxAmount: (item['taxAmount'] as num).toDouble(),
            amount: (item['amount'] as num).toDouble(),
          ),
        )
        .toList();

    return CreatePurchaseRequest(
      supplierId: json['supplierId'] as String,
      billNo: json['billNo'] as String?,
      challanNo: json['challanNo'] as String?,
      noteNo: json['noteNo'] as String?,
      payMode: json['payMode'] as String,
      tpNo: json['tpNo'] as String?,
      tpDate: json['tpDate'] as String?,
      stNo: json['stNo'] as String?,
      discount: (json['discount'] as num).toDouble(),
      vat: (json['vat'] as num).toDouble(),
      stamp: (json['stamp'] as num).toDouble(),
      tcs: (json['tcs'] as num).toDouble(),
      loadingFreight: (json['loadingFreight'] as num).toDouble(),
      netAmount: (json['netAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      lineItems: items,
    );
  }
}
