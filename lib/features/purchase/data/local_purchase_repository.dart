import 'dart:convert';

import 'package:drift/drift.dart' hide Column;

import '../../../core/local/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../masters/data/local_masters_repository.dart';
import '../../masters/data/models/supplier_dto.dart';
import '../../sales/data/models/material_dto.dart';
import 'models/create_purchase_request.dart';
import 'models/purchase_return_models.dart';
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

        if (row.operation == 'return') {
          await _remote.returnPurchaseBill(row.entityId);
          await (_db.delete(_db.syncQueueItems)..where((tbl) => tbl.id.equals(row.id))).go();
          continue;
        }

        final request = _decodeRequest(row.payload);
        final syncedRequest = await _resolveDependencies(request);
        final result = await _remote.createPurchase(syncedRequest);
        await _persistPurchase(
          purchaseId: result.id,
          request: syncedRequest,
          syncStatus: 'synced',
          billNo: result.billNo,
        );
        await _applyPurchaseToLocalInventory(syncedRequest, persistOnlyMissing: true);

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

  Future<List<PurchaseBillDetailDto>> getPurchaseBills({String? search, DateTime? date}) async {
    try {
      await syncPendingPurchases();
      return await _remote.getPurchaseBills(search: search, date: date);
    } on ApiException {
      final query = _db.select(_db.cachedPurchaseBills)
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
      if (date != null) {
        final start = DateTime(date.year, date.month, date.day);
        final end = start.add(const Duration(days: 1));
        query.where((tbl) => tbl.billDate.isBiggerOrEqualValue(start) & tbl.billDate.isSmallerThanValue(end));
      }
      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim().toLowerCase();
        query.where((tbl) =>
            (tbl.billNo.isNotNull() & tbl.billNo.lower().contains(s)) |
            (tbl.challanNo.isNotNull() & tbl.challanNo.lower().contains(s)));
      }
      final billRows = await query.get();
      final result = <PurchaseBillDetailDto>[];

      for (final bill in billRows) {
        final supplier = await (_db.select(_db.cachedSuppliers)..where((tbl) => tbl.id.equals(bill.supplierId))).getSingleOrNull();
        final lineRows = await (_db.select(_db.cachedPurchaseLineItems)
              ..where((tbl) => tbl.purchaseBillId.equals(bill.id))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.lineNumber)]))
            .get();

        final lineDtos = <PurchaseLineItemDetailDto>[];
        for (final li in lineRows) {
          final material = await (_db.select(_db.cachedMaterials)..where((tbl) => tbl.id.equals(li.materialId))).getSingleOrNull();
          lineDtos.add(PurchaseLineItemDetailDto(
            id: li.id,
            purchaseBillId: li.purchaseBillId,
            materialId: li.materialId,
            materialName: material?.name ?? li.materialId,
            batchNo: li.batchNo,
            packing: li.packing,
            qty: li.qty,
            rate: li.rate,
            disPercent: li.disPercent,
            disAmount: li.disAmount,
            taxPercent: li.taxPercent,
            taxAmount: li.taxAmount,
            amount: li.amount,
            lineNumber: li.lineNumber,
          ));
        }

        result.add(PurchaseBillDetailDto(
          id: bill.id,
          billNo: bill.billNo,
          supplierId: bill.supplierId,
          supplierName: supplier?.name ?? 'Supplier',
          challanNo: bill.challanNo,
          noteNo: bill.noteNo,
          payMode: bill.payMode,
          tpNo: bill.tpNo,
          tpDate: bill.tpDate,
          stNo: bill.stNo,
          discount: bill.discount,
          vat: bill.vat,
          stamp: bill.stamp,
          tcs: bill.tcs,
          loadingFreight: bill.loadingFreight,
          netAmount: bill.netAmount,
          totalAmount: bill.totalAmount,
          billDate: bill.billDate.toIso8601String(),
          status: 'saved',
          createdAt: bill.createdAt.toIso8601String(),
          lineItems: lineDtos,
        ));
      }

      return result;
    }
  }

  Future<void> returnPurchaseBill(String billId) async {
    var remoteSucceeded = false;
    try {
      await _remote.returnPurchaseBill(billId);
      remoteSucceeded = true;
    } on ApiException catch (e) {
      if (e.statusCode != null && e.statusCode != 404) {
        rethrow;
      }
    }

    await _db.transaction(() async {
      final lineItems = await (_db.select(_db.cachedPurchaseLineItems)
            ..where((tbl) => tbl.purchaseBillId.equals(billId)))
          .get();

      for (final item in lineItems) {
        final stock = await (_db.select(_db.cachedInventoryStocks)
              ..where((tbl) => tbl.materialId.equals(item.materialId)))
            .getSingleOrNull();

        if (stock != null) {
          await (_db.update(_db.cachedInventoryStocks)
                ..where((tbl) => tbl.materialId.equals(item.materialId)))
              .write(
            CachedInventoryStocksCompanion(
              qtyOnHand: Value((stock.qtyOnHand - item.qty).clamp(0, 999999)),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
        }
      }

      await (_db.delete(_db.cachedPurchaseLineItems)..where((tbl) => tbl.purchaseBillId.equals(billId))).go();
      await (_db.delete(_db.cachedPurchaseBills)..where((tbl) => tbl.id.equals(billId))).go();
      await (_db.delete(_db.syncQueueItems)..where((tbl) => tbl.entityId.equals(billId))).go();

      if (!remoteSucceeded && !billId.startsWith('local-')) {
        await _db.into(_db.syncQueueItems).insert(
              SyncQueueItemsCompanion.insert(
                entityType: 'purchase',
                entityId: billId,
                operation: 'return',
                payload: jsonEncode({'id': billId}),
                status: const Value('pending'),
                updatedAt: Value(DateTime.now().toUtc()),
              ),
            );
      }
    });
  }

  Future<CreatePurchaseResult> createPurchase(CreatePurchaseRequest request) async {
    try {
      await syncPendingPurchases();
      final syncedRequest = await _resolveDependencies(request);
      final result = await _remote.createPurchase(syncedRequest);
      await _persistPurchase(
        purchaseId: result.id,
        request: syncedRequest,
        syncStatus: 'synced',
        billNo: result.billNo,
      );
      await _applyPurchaseToLocalInventory(syncedRequest);
      return result;
    } on ApiException catch (e) {
      if (e.statusCode != null) rethrow;

      final localId = 'local-purchase-${DateTime.now().microsecondsSinceEpoch}';
      await _persistPurchase(
        purchaseId: localId,
        request: request,
        syncStatus: 'pending_create',
        billNo: request.billNo,
      );
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
      await _applyPurchaseToLocalInventory(request);

      return CreatePurchaseResult(
        id: localId,
        billNo: request.billNo ?? 'Offline Queue',
        lineItemCount: request.lineItems.length,
        isPendingSync: true,
      );
    }
  }

  Future<void> _persistPurchase({
    required String purchaseId,
    required CreatePurchaseRequest request,
    required String syncStatus,
    String? billNo,
  }) async {
    final now = DateTime.now().toUtc();
    final billDate = DateTime(now.year, now.month, now.day);

    await _db.transaction(() async {
      await (_db.delete(_db.cachedPurchaseLineItems)..where((tbl) => tbl.purchaseBillId.equals(purchaseId))).go();

      await _db.into(_db.cachedPurchaseBills).insert(
            CachedPurchaseBillsCompanion.insert(
              id: purchaseId,
              supplierId: request.supplierId,
              billNo: Value(billNo ?? request.billNo),
              challanNo: Value(request.challanNo),
              noteNo: Value(request.noteNo),
              payMode: request.payMode,
              tpNo: Value(request.tpNo),
              tpDate: Value(request.tpDate),
              stNo: Value(request.stNo),
              discount: request.discount,
              vat: request.vat,
              stamp: request.stamp,
              tcs: request.tcs,
              loadingFreight: request.loadingFreight,
              netAmount: request.netAmount,
              totalAmount: request.totalAmount,
              syncStatus: Value(syncStatus),
              billDate: billDate,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
            mode: InsertMode.insertOrReplace,
          );

      for (var i = 0; i < request.lineItems.length; i++) {
        final item = request.lineItems[i];
        await _db.into(_db.cachedPurchaseLineItems).insert(
              CachedPurchaseLineItemsCompanion.insert(
                id: '$purchaseId-line-${i + 1}',
                purchaseBillId: purchaseId,
                materialId: item.materialId,
                batchNo: item.batchNo,
                packing: Value(item.packing),
                qty: item.qty,
                rate: item.rate,
                disPercent: item.disPercent,
                disAmount: item.disAmount,
                taxPercent: item.taxPercent,
                taxAmount: item.taxAmount,
                amount: item.amount,
                lineNumber: i + 1,
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
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

  Future<void> _applyPurchaseToLocalInventory(
    CreatePurchaseRequest request, {
    bool persistOnlyMissing = false,
  }) async {
    final now = DateTime.now().toUtc();

    for (final item in request.lineItems) {
      final material = await (_db.select(_db.cachedMaterials)..where((tbl) => tbl.id.equals(item.materialId))).getSingleOrNull();
      final existing = await (_db.select(_db.cachedInventoryStocks)..where((tbl) => tbl.materialId.equals(item.materialId))).getSingleOrNull();

      if (persistOnlyMissing && existing != null) continue;

      await _db.into(_db.cachedInventoryStocks).insert(
            CachedInventoryStocksCompanion.insert(
              materialId: item.materialId,
              barcode: material?.barcode ?? item.materialId,
              name: material?.name ?? item.materialId,
              category: material?.category ?? 'Unknown',
              qtyOnHand: (existing?.qtyOnHand ?? 0) + item.qty,
              reorderLevel: Value(existing?.reorderLevel ?? 10),
              updatedAt: Value(now),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }
  }
}
