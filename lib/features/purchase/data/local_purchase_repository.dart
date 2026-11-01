import 'dart:convert';

import 'package:drift/drift.dart' hide Column;

import '../../../core/config/app_config.dart';
import '../../../core/local/app_database.dart';
import '../../../core/local/db_paths.dart';
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
    if (!AppConfig.offlineOnly) {
      try {
        await syncPendingPurchases();
      } on ApiException {
        // Keep supplier dropdown available from local cache below.
      }
    }
    return _masters.getSuppliers();
  }

  Future<MaterialDto?> getMaterialByBarcode(String barcode) async {
    if (!AppConfig.offlineOnly) {
      try {
        await syncPendingPurchases();
      } on ApiException {
        // Keep material lookup available from local cache below.
      }
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
        await _persistPurchaseWithStock(
          purchaseId: result.id,
          request: syncedRequest,
          syncStatus: 'synced',
          billNo: result.billNo,
        );
        // Note: stock already updated by _persistPurchaseWithStock

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
    if (!AppConfig.offlineOnly) {
      try {
        await syncPendingPurchases();
        return await _remote.getPurchaseBills(search: search, date: date);
      } on ApiException {
        // fall through to local query
      }
    }
    final query = _db.select(_db.cachedPurchaseBills)
      ..where(_db.isActivePurchaseBill)
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

  /// Returns some or all of a purchase to the supplier.
  ///
  /// Every returned quantity is logged in `purchase_return_entries` and
  /// deducted from stock (refused if stock is too low — you can't send back
  /// bottles you've already sold). A partial return reduces the bill's lines
  /// as before; when nothing is left the bill is kept and marked returned
  /// (never deleted), and every report and list excludes it.
  Future<void> returnPurchaseBill(
    String billId, {
    List<int>? lineNumbers,
    Map<int, int>? lineQuantities,
    String? returnedBy,
  }) async {
    final deviceId = await _db.deviceId();
    await _db.transaction(() async {
      final bill = await (_db.select(_db.cachedPurchaseBills)..where((tbl) => tbl.id.equals(billId))).getSingleOrNull();
      if (bill == null) return;
      if (bill.returnedAt != null) {
        throw ApiException('Purchase ${bill.billNo ?? ''} has already been fully returned.'.replaceAll('  ', ' '));
      }

      final allLineItems = await (_db.select(_db.cachedPurchaseLineItems)
            ..where((tbl) => tbl.purchaseBillId.equals(billId)))
          .get();
      if (allLineItems.isEmpty) return;

      final selectedLineNumbers = lineQuantities != null
          ? lineQuantities.keys.toSet()
          : (lineNumbers != null ? lineNumbers.toSet() : allLineItems.map((e) => e.lineNumber).toSet());

      final returningItems = allLineItems.where((li) => selectedLineNumbers.contains(li.lineNumber)).toList();
      if (returningItems.isEmpty) return;

      final now = DateTime.now();
      final returnedQty = <int, int>{
        for (final item in returningItems)
          item.lineNumber: (lineQuantities != null && lineQuantities.containsKey(item.lineNumber))
              ? lineQuantities[item.lineNumber]!.clamp(1, item.qty)
              : item.qty,
      };
      final isFullReturn = allLineItems.every((li) => (returnedQty[li.lineNumber] ?? 0) >= li.qty);

      // Check stock for every line first so a refusal changes nothing.
      final needByMaterial = <String, int>{};
      for (final item in returningItems) {
        needByMaterial[item.materialId] = (needByMaterial[item.materialId] ?? 0) + returnedQty[item.lineNumber]!;
      }
      for (final e in needByMaterial.entries) {
        final stock = await (_db.select(_db.cachedInventoryStocks)..where((tbl) => tbl.materialId.equals(e.key)))
            .getSingleOrNull();
        final onHand = stock?.qtyOnHand ?? 0;
        if (onHand < e.value) {
          final name = stock?.name ?? e.key;
          throw ApiException('Cannot return $name: only $onHand in stock, ${e.value} requested.');
        }
      }

      for (final item in returningItems) {
        final returnQty = returnedQty[item.lineNumber]!;

        await _db.into(_db.purchaseReturnEntries).insert(PurchaseReturnEntriesCompanion.insert(
              id: DbPaths.newId(),
              purchaseBillId: billId,
              billNo: Value(bill.billNo),
              supplierId: bill.supplierId,
              lineNumber: item.lineNumber,
              materialId: item.materialId,
              batchNo: item.batchNo,
              quantity: returnQty,
              rate: item.rate,
              amount: item.qty == 0 ? 0 : item.amount * returnQty / item.qty,
              isFullBillReturn: Value(isFullReturn),
              returnedBy: Value(returnedBy),
              deviceId: Value(deviceId),
              returnedAt: now,
            ));

        final stock = await (_db.select(_db.cachedInventoryStocks)..where((tbl) => tbl.materialId.equals(item.materialId)))
            .getSingle();
        await (_db.update(_db.cachedInventoryStocks)..where((tbl) => tbl.materialId.equals(item.materialId))).write(
          CachedInventoryStocksCompanion(
            qtyOnHand: Value(stock.qtyOnHand - returnQty),
            updatedAt: Value(now.toUtc()),
          ),
        );

        // On a full return the lines stay exactly as purchased.
        if (isFullReturn) continue;

        if (returnQty < item.qty) {
          final remainingQty = item.qty - returnQty;
          await (_db.update(_db.cachedPurchaseLineItems)
                ..where((tbl) => tbl.purchaseBillId.equals(billId) & tbl.lineNumber.equals(item.lineNumber)))
              .write(CachedPurchaseLineItemsCompanion(
            qty: Value(remainingQty),
            amount: Value(remainingQty * item.rate),
          ));
        } else {
          await (_db.delete(_db.cachedPurchaseLineItems)
                ..where((tbl) => tbl.purchaseBillId.equals(billId) & tbl.lineNumber.equals(item.lineNumber)))
              .go();
        }
      }

      if (isFullReturn) {
        var remoteSucceeded = false;
        if (!AppConfig.offlineOnly) {
          try {
            await _remote.returnPurchaseBill(billId);
            remoteSucceeded = true;
          } on ApiException catch (e) {
            if (e.statusCode != null && e.statusCode != 404) rethrow;
          }
        }

        await (_db.update(_db.cachedPurchaseBills)..where((tbl) => tbl.id.equals(billId))).write(
          CachedPurchaseBillsCompanion(
            returnedAt: Value(now),
            returnedBy: Value(returnedBy),
            updatedAt: Value(now.toUtc()),
          ),
        );

        await (_db.delete(_db.syncQueueItems)..where((tbl) => tbl.entityId.equals(billId))).go();
        if (!remoteSucceeded && !billId.startsWith('local-')) {
          await _db.into(_db.syncQueueItems).insert(
                SyncQueueItemsCompanion.insert(
                  entityType: 'purchase',
                  entityId: billId,
                  operation: 'return',
                  payload: jsonEncode({'id': billId}),
                  status: const Value('pending'),
                  updatedAt: Value(now.toUtc()),
                ),
              );
        }
        return;
      }

      final remainingLineItems = await (_db.select(_db.cachedPurchaseLineItems)
            ..where((tbl) => tbl.purchaseBillId.equals(billId)))
          .get();
      final newTotalAmount = remainingLineItems.fold<double>(0.0, (sum, i) => sum + i.amount);
      final newNetAmount = newTotalAmount - bill.discount + bill.vat + bill.stamp + bill.tcs + bill.loadingFreight;
      await (_db.update(_db.cachedPurchaseBills)..where((tbl) => tbl.id.equals(billId))).write(
        CachedPurchaseBillsCompanion(
          totalAmount: Value(newTotalAmount),
          netAmount: Value(newNetAmount),
          updatedAt: Value(now.toUtc()),
        ),
      );
    });
  }

  Future<CreatePurchaseResult> createPurchase(CreatePurchaseRequest request) async {
    if (AppConfig.offlineOnly) {
      // In offline mode, all IDs are already local — no _resolveDependencies needed.
      return _createLocalPurchase(request);
    }
    try {
      await syncPendingPurchases();
      final syncedRequest = await _resolveDependencies(request);
      final result = await _remote.createPurchase(syncedRequest);
      await _persistPurchaseWithStock(
        purchaseId: result.id,
        request: syncedRequest,
        syncStatus: 'synced',
        billNo: result.billNo,
      );
      return result;
    } on ApiException catch (e) {
      if (e.statusCode != null) rethrow;
      return _createLocalPurchase(request);
    }
  }

  /// Saves the purchase, applies stock and queues the sync job in one
  /// transaction, so a crash can't leave stock changed without a bill.
  Future<CreatePurchaseResult> _createLocalPurchase(CreatePurchaseRequest request) async {
    final localId = 'local-purchase-${DbPaths.newId()}';
    final deviceId = await _db.deviceId();
    await _db.transaction(() async {
      await _persistPurchaseWithStock(
        purchaseId: localId,
        request: request,
        syncStatus: 'pending_create',
        billNo: request.billNo,
        deviceId: deviceId,
      );
      final payload = request.toJson()
        ..['deviceId'] = deviceId
        ..['clientId'] = localId;
      await _db.into(_db.syncQueueItems).insert(
            SyncQueueItemsCompanion.insert(
              entityType: 'purchase',
              entityId: localId,
              operation: 'create',
              payload: jsonEncode(payload),
              status: const Value('pending'),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
    });
    return CreatePurchaseResult(
      id: localId,
      billNo: request.billNo ?? 'Offline Queue',
      lineItemCount: request.lineItems.length,
      isPendingSync: true,
    );
  }

  /// Persists the purchase bill + line items AND applies stock changes,
  /// all inside one transaction.  Batch-inserts line items for speed.
  Future<void> _persistPurchaseWithStock({
    required String purchaseId,
    required CreatePurchaseRequest request,
    required String syncStatus,
    String? billNo,
    String? deviceId,
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
              deviceId: Value(deviceId),
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

      // Batch-insert line items
      await _db.batch((batch) {
        for (var i = 0; i < request.lineItems.length; i++) {
          final item = request.lineItems[i];
          batch.insert(
            _db.cachedPurchaseLineItems,
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

      // Stock adjustment: purchase adds stock (inside same transaction)
      for (final item in request.lineItems) {
        final material = await (_db.select(_db.cachedMaterials)..where((tbl) => tbl.id.equals(item.materialId))).getSingleOrNull();
        final existing = await (_db.select(_db.cachedInventoryStocks)..where((tbl) => tbl.materialId.equals(item.materialId))).getSingleOrNull();

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
}
