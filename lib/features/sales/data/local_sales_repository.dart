import 'dart:convert';

import 'package:drift/drift.dart' hide Column;

import '../../../core/config/app_config.dart';
import '../../../core/local/app_database.dart';
import '../../../core/local/db_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../masters/data/local_masters_repository.dart';
import 'models/create_sale_request.dart';
import 'models/customer_dto.dart';
import 'models/material_dto.dart';
import 'models/sales_bill_dto.dart';
import 'models/sales_return_models.dart';
import 'sales_api_repository.dart';

class LocalSalesRepository {
  LocalSalesRepository(this._db, this._remote, this._masters);

  final AppDatabase _db;
  final SalesApiRepository _remote;
  final LocalMastersRepository _masters;

  Future<List<SalesBillDto>> getTodaysBills() async {

    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final rows = await (_db.select(_db.cachedSalesBills)
          ..where((tbl) =>
              _db.isActiveSaleBill(tbl) &
              tbl.billDate.isBiggerOrEqualValue(dayStart) &
              tbl.billDate.isSmallerThanValue(dayEnd))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();

    return rows.map((row) {
      return SalesBillDto(
        id: row.id,
        billNo: row.billNo,
        billDate: row.billDate.toIso8601String(),
        payMode: row.payMode,
        totalAmount: row.totalAmount,
        balanceDue: row.balanceDue,
        status: row.syncStatus == 'synced' ? row.status : 'pending sync',
        lineItemCount: 0,
      );
    }).toList();
  }

  /// Most recent bills shown in the Sales Return list. Search / date
  /// filters run in SQL first, so any older bill is still findable.
  static const recentBillsLimit = 300;

  SimpleSelectStatement<$CachedSalesBillsTable, CachedSalesBill> _billsQuery({String? search, DateTime? date}) {
    final q = _db.select(_db.cachedSalesBills)
      ..where(_db.isActiveSaleBill)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
      ..limit(recentBillsLimit);
    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      q.where((tbl) => tbl.billDate.isBiggerOrEqualValue(start) & tbl.billDate.isSmallerThanValue(end));
    }
    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim().toLowerCase();
      q.where((tbl) => tbl.billNo.lower().contains(s));
    }
    return q;
  }

  /// Attaches line items with ONE query (was one query per bill).
  Future<List<SalesBillDetailDto>> _withLines(List<CachedSalesBill> bills) async {
    if (bills.isEmpty) return const [];
    final lines = await (_db.select(_db.cachedSaleLineItems)
          ..where((tbl) => tbl.salesBillId.isIn(bills.map((b) => b.id)))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.lineNumber)]))
        .get();
    final byBill = <String, List<CachedSaleLineItem>>{};
    for (final l in lines) {
      byBill.putIfAbsent(l.salesBillId, () => []).add(l);
    }
    return [
      for (final bill in bills)
        SalesBillDetailDto(
          id: bill.id,
          billNo: bill.billNo,
          customerId: bill.customerId,
          billType: 'CounterSale.Sale',
          billDate: bill.billDate.toIso8601String(),
          payMode: bill.payMode,
          taxableValue: bill.totalAmount - bill.totalTax,
          totalDiscount: 0,
          totalTax: bill.totalTax,
          totalAmount: bill.totalAmount,
          balanceDue: bill.balanceDue,
          status: bill.status,
          createdAt: bill.createdAt.toIso8601String(),
          lineItems: [
            for (final li in byBill[bill.id] ?? const <CachedSaleLineItem>[])
              SaleLineItemDetailDto(
                id: li.id,
                salesBillId: li.salesBillId,
                barcodeNo: li.barcodeNo,
                materialId: li.materialId,
                materialType: li.materialType,
                materialName: li.materialName,
                batchNo: li.batchNo,
                packing: li.packing,
                quantity: li.quantity,
                qtyCase: li.qtyCase,
                rate: li.rate,
                discountPercent: li.discountPercent,
                discountAmount: li.discountAmount,
                taxPercent: li.taxPercent,
                taxAmount: li.taxAmount,
                amount: li.amount,
                lineNumber: li.lineNumber,
              ),
          ],
        ),
    ];
  }

  Future<List<SalesBillDetailDto>> getSalesBills({String? search, DateTime? date}) async =>
      _withLines(await _billsQuery(search: search, date: date).get());

  Stream<List<SalesBillDetailDto>> watchSalesBills({String? search, DateTime? date}) =>
      _billsQuery(search: search, date: date).watch().asyncMap(_withLines);

  /// Returns some or all of a bill.
  ///
  /// Every returned quantity is written to `sales_return_entries` (the
  /// permanent audit record) and stock is restored. A partial return
  /// reduces the bill's lines as before. When nothing is left on the bill
  /// it is kept and marked `returned` — never deleted — and every report
  /// excludes it, so report figures are exactly what they were before.
  Future<void> returnSalesBill(
    String billId, {
    List<int>? lineNumbers,
    Map<int, int>? lineQuantities,
    String? returnedBy,
  }) async {
    final deviceId = await _db.deviceId();
    await _db.transaction(() async {
      final bill = await (_db.select(_db.cachedSalesBills)..where((tbl) => tbl.id.equals(billId))).getSingleOrNull();
      if (bill == null) return;
      if (bill.status == AppDatabase.saleStatusReturned) {
        throw ApiException('Bill ${bill.billNo} has already been fully returned.');
      }

      final allLineItems = await (_db.select(_db.cachedSaleLineItems)
            ..where((tbl) => tbl.salesBillId.equals(billId)))
          .get();
      if (allLineItems.isEmpty) return;

      final selectedLineNumbers = lineQuantities != null
          ? lineQuantities.keys.toSet()
          : (lineNumbers != null ? lineNumbers.toSet() : allLineItems.map((e) => e.lineNumber).toSet());

      final returningItems = allLineItems.where((li) => selectedLineNumbers.contains(li.lineNumber)).toList();
      if (returningItems.isEmpty) return;

      final now = DateTime.now();
      final returnedQty = <int, int>{};
      for (final item in returningItems) {
        returnedQty[item.lineNumber] = (lineQuantities != null && lineQuantities.containsKey(item.lineNumber))
            ? lineQuantities[item.lineNumber]!.clamp(1, item.quantity)
            : item.quantity;
      }
      final isFullReturn = allLineItems.every((li) => (returnedQty[li.lineNumber] ?? 0) >= li.quantity);

      for (final item in returningItems) {
        final returnQty = returnedQty[item.lineNumber]!;

        // Permanent audit record of this return.
        await _db.into(_db.salesReturnEntries).insert(SalesReturnEntriesCompanion.insert(
              id: DbPaths.newId(),
              salesBillId: billId,
              billNo: bill.billNo,
              lineNumber: item.lineNumber,
              materialId: Value(item.materialId),
              barcodeNo: item.barcodeNo,
              materialName: item.materialName,
              quantity: returnQty,
              rate: item.rate,
              amount: item.quantity == 0 ? 0 : item.amount * returnQty / item.quantity,
              isFullBillReturn: Value(isFullReturn),
              returnedBy: Value(returnedBy),
              deviceId: Value(deviceId),
              returnedAt: now,
            ));

        // Restore stock by exact returnQty.
        if (item.materialId != null) {
          final stock = await (_db.select(_db.cachedInventoryStocks)
                ..where((tbl) => tbl.materialId.equals(item.materialId!)))
              .getSingleOrNull();
          if (stock != null) {
            await (_db.update(_db.cachedInventoryStocks)..where((tbl) => tbl.materialId.equals(item.materialId!)))
                .write(CachedInventoryStocksCompanion(
              qtyOnHand: Value(stock.qtyOnHand + returnQty),
              updatedAt: Value(now.toUtc()),
            ));
          }
        }

        // On a full return the lines stay exactly as sold (for the record).
        if (isFullReturn) continue;

        if (returnQty < item.quantity) {
          final remainingQty = item.quantity - returnQty;
          final base = remainingQty * item.rate;
          final discAmt = base * (item.discountPercent / 100.0);
          final taxable = base - discAmt;
          final taxAmt = taxable * (item.taxPercent / 100.0);
          final lineAmt = taxable + taxAmt;

          await (_db.update(_db.cachedSaleLineItems)
                ..where((tbl) => tbl.salesBillId.equals(billId) & tbl.lineNumber.equals(item.lineNumber)))
              .write(CachedSaleLineItemsCompanion(
            quantity: Value(remainingQty),
            discountAmount: Value(discAmt),
            taxAmount: Value(taxAmt),
            amount: Value(lineAmt),
          ));
        } else {
          await (_db.delete(_db.cachedSaleLineItems)
                ..where((tbl) => tbl.salesBillId.equals(billId) & tbl.lineNumber.equals(item.lineNumber)))
              .go();
        }
      }

      if (isFullReturn) {
        var remoteSucceeded = false;
        if (!AppConfig.offlineOnly) {
          try {
            await _remote.returnSalesBill(billId);
            remoteSucceeded = true;
          } on ApiException catch (e) {
            if (e.statusCode != null && e.statusCode != 404) rethrow;
          }
        }

        await (_db.update(_db.cachedSalesBills)..where((tbl) => tbl.id.equals(billId))).write(
          CachedSalesBillsCompanion(
            status: const Value(AppDatabase.saleStatusReturned),
            returnedAt: Value(now),
            returnedBy: Value(returnedBy),
            updatedAt: Value(now.toUtc()),
          ),
        );

        // Sync: a never-synced bill simply drops out of the queue; a synced
        // one gets a 'return' job. (Unchanged from before.)
        await (_db.delete(_db.syncQueueItems)..where((tbl) => tbl.entityId.equals(billId))).go();
        if (!remoteSucceeded && !billId.startsWith('local-')) {
          await _db.into(_db.syncQueueItems).insert(
                SyncQueueItemsCompanion.insert(
                  entityType: 'sale',
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

      final remainingLineItems = await (_db.select(_db.cachedSaleLineItems)
            ..where((tbl) => tbl.salesBillId.equals(billId)))
          .get();
      await (_db.update(_db.cachedSalesBills)..where((tbl) => tbl.id.equals(billId))).write(
        CachedSalesBillsCompanion(
          totalAmount: Value(remainingLineItems.fold<double>(0.0, (sum, i) => sum + i.amount)),
          totalTax: Value(remainingLineItems.fold<double>(0.0, (sum, i) => sum + i.taxAmount)),
          updatedAt: Value(now.toUtc()),
        ),
      );
    });
  }

  Future<MaterialDto?> getMaterialByBarcode(String barcode) async {
    return _masters.getMaterialByBarcode(barcode);
  }

  Future<List<CustomerDto>> getCustomers() async {
    if (AppConfig.offlineOnly) return const [];
    try {
      return await _remote.getCustomers();
    } on ApiException {
      return const [];
    }
  }

  Stream<int> watchPendingSalesSyncCount() {
    return _masters.watchPendingSyncCount(entityTypes: {'sale'});
  }

  Future<void> syncPendingSales() async {
    await _masters.syncPendingMasters();

    final rows = await (_db.select(_db.syncQueueItems)
          ..where((tbl) => tbl.entityType.equals('sale') & tbl.status.equals('pending'))
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
          await _remote.returnSalesBill(row.entityId);
          await (_db.delete(_db.syncQueueItems)..where((tbl) => tbl.id.equals(row.id))).go();
          continue;
        }

        final request = _decodeRequest(row.payload);
        final syncedRequest = await _resolveDependencies(request);
        final result = await _remote.createSale(syncedRequest);

        await _db.transaction(() async {
          await _replaceLocalSaleWithSynced(
            localId: row.entityId,
            syncedId: result.id,
            request: syncedRequest,
            syncedBillNo: result.billNo,
          );
          await (_db.delete(_db.syncQueueItems)..where((tbl) => tbl.id.equals(row.id))).go();
        });
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

  Future<CreateSaleResult> createSale(CreateSaleRequest request) async {
    // Local-first: persist immediately, queue for background sync.
    // Never blocks on network — sync happens via Sync Center.
    //
    // Everything happens in ONE transaction: the bill number is reserved,
    // stock is checked and deducted, the bill is written and the sync job
    // is queued — or none of it happens. A crash can't leave a saved bill
    // without its sync job, or burn/duplicate a bill number.
    final localId = 'local-sale-${DbPaths.newId()}';
    final deviceId = await _db.deviceId();
    late String billNo;

    await _db.transaction(() async {
      billNo = await _db.reserveNextSalesBillNo();
      await _persistSale(
        saleId: localId,
        request: request,
        syncStatus: 'pending_create',
        status: 'pending sync',
        billNo: billNo,
        deviceId: deviceId,
      );
      final payload = request.toJson()
        ..['billNo'] = billNo
        ..['billDate'] = _isoDate(DateTime.now())
        ..['deviceId'] = deviceId
        ..['clientId'] = localId;
      await _db.into(_db.syncQueueItems).insert(
            SyncQueueItemsCompanion.insert(
              entityType: 'sale',
              entityId: localId,
              operation: 'create',
              payload: jsonEncode(payload),
              status: const Value('pending'),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
    });

    return CreateSaleResult(
      id: localId,
      billNo: billNo,
      lineItemCount: request.lineItems.length,
      isPendingSync: true,
    );
  }

  Future<CreateSaleRequest> _resolveDependencies(CreateSaleRequest request) async {
    final lineItems = <CreateSaleLineItemRequest>[];
    for (final item in request.lineItems) {
      final materialId = item.materialId == null ? null : await _resolveMaterialId(item.materialId!);
      lineItems.add(
        CreateSaleLineItemRequest(
          materialId: materialId,
          barcodeNo: item.barcodeNo,
          materialType: item.materialType,
          materialName: item.materialName,
          batchNo: item.batchNo,
          packing: item.packing,
          quantity: item.quantity,
          qtyCase: item.qtyCase,
          rate: item.rate,
          discountPercent: item.discountPercent,
          discountAmount: item.discountAmount,
          taxPercent: item.taxPercent,
          taxAmount: item.taxAmount,
          amount: item.amount,
        ),
      );
    }

    return CreateSaleRequest(
      billNo: request.billNo,
      customerId: request.customerId,
      payMode: request.payMode,
      taxableValue: request.taxableValue,
      totalDiscount: request.totalDiscount,
      totalTax: request.totalTax,
      totalAmount: request.totalAmount,
      balanceDue: request.balanceDue,
      lineItems: lineItems,
    );
  }

  Future<String> _resolveMaterialId(String id) async {
    final material = await (_db.select(_db.cachedMaterials)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (material == null) return id;
    if (material.syncStatus == 'synced' || material.syncStatus == 'pending_create') return material.id;

    throw const ApiException('A selected material is not ready to sync yet.');
  }

  Future<void> _persistSale({
    required String saleId,
    required CreateSaleRequest request,
    required String syncStatus,
    required String status,
    required String billNo,
    String? deviceId,
  }) async {
    final now = DateTime.now();
    final billDate = now;

    await _db.transaction(() async {
      await (_db.delete(_db.cachedSaleLineItems)..where((tbl) => tbl.salesBillId.equals(saleId))).go();

      await _db.into(_db.cachedSalesBills).insert(
            CachedSalesBillsCompanion.insert(
              id: saleId,
              billNo: billNo,
              customerId: Value(request.customerId),
              permitNo: Value(request.permitNo),
              permitHolderName: Value(request.permitHolderName),
              deviceId: Value(deviceId),
              payMode: request.payMode,
              status: status,
              totalAmount: request.totalAmount,
              balanceDue: request.balanceDue,
              totalTax: request.totalTax,
              syncStatus: Value(syncStatus),
              billDate: billDate,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
            mode: InsertMode.insertOrReplace,
          );

      await _db.batch((batch) {
        for (var i = 0; i < request.lineItems.length; i++) {
          final item = request.lineItems[i];
          batch.insert(
            _db.cachedSaleLineItems,
            CachedSaleLineItemsCompanion.insert(
              id: '$saleId-line-${i + 1}',
              salesBillId: saleId,
              materialId: Value(item.materialId),
              barcodeNo: item.barcodeNo,
              materialType: item.materialType,
              materialName: item.materialName,
              batchNo: Value(item.batchNo),
              packing: Value(item.packing),
              quantity: item.quantity,
              qtyCase: Value(item.qtyCase),
              rate: item.rate,
              discountPercent: item.discountPercent,
              discountAmount: item.discountAmount,
              taxPercent: item.taxPercent,
              taxAmount: item.taxAmount,
              amount: item.amount,
              lineNumber: i + 1,
            ),
          );
        }
      });

      // Verify stock exists and is sufficient for all items.
      // Prevents negative values in the inventory.
      for (final item in request.lineItems) {
        final query = _db.select(_db.cachedInventoryStocks);
        if (item.materialId != null && item.materialId!.isNotEmpty) {
          query.where((tbl) => tbl.materialId.equals(item.materialId!));
        } else {
          query.where((tbl) => tbl.barcode.equals(item.barcodeNo));
        }
        final stock = await query.getSingleOrNull();

        if (stock == null) {
          throw ApiException(
            'Cannot sell "${item.materialName}": Item is not present in inventory.',
          );
        }
        if (stock.qtyOnHand <= 0) {
          throw ApiException(
            'Cannot sell "${item.materialName}": Item is out of stock (0 on hand in inventory).',
          );
        }
        if (stock.qtyOnHand < item.quantity) {
          throw ApiException(
            'Cannot sell "${item.materialName}": Insufficient inventory (${stock.qtyOnHand} available, ${item.quantity} requested).',
          );
        }
      }

      // Stock deduction: sale deducts stock (inside same transaction).
      for (final item in request.lineItems) {
        final query = _db.select(_db.cachedInventoryStocks);
        if (item.materialId != null && item.materialId!.isNotEmpty) {
          query.where((tbl) => tbl.materialId.equals(item.materialId!));
        } else {
          query.where((tbl) => tbl.barcode.equals(item.barcodeNo));
        }
        final stock = await query.getSingleOrNull();

        if (stock != null) {
          final newQty = (stock.qtyOnHand - item.quantity).clamp(0, 999999);
          await (_db.update(_db.cachedInventoryStocks)
                ..where((tbl) => tbl.materialId.equals(stock.materialId)))
              .write(
            CachedInventoryStocksCompanion(
              qtyOnHand: Value(newQty),
              updatedAt: Value(now),
            ),
          );
        }
      }
    });
  }

  Future<void> _replaceLocalSaleWithSynced({
    required String localId,
    required String syncedId,
    required CreateSaleRequest request,
    required String syncedBillNo,
  }) async {
    await (_db.delete(_db.cachedSaleLineItems)..where((tbl) => tbl.salesBillId.equals(localId))).go();
    await (_db.delete(_db.cachedSalesBills)..where((tbl) => tbl.id.equals(localId))).go();
    await _persistSale(
      saleId: syncedId,
      request: request,
      syncStatus: 'synced',
      status: 'paid',
      billNo: syncedBillNo,
    );
  }

  CreateSaleRequest _decodeRequest(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final items = (json['lineItems'] as List<dynamic>)
        .map(
          (item) => CreateSaleLineItemRequest(
            materialId: item['materialId'] as String?,
            barcodeNo: item['barcodeNo'] as String,
            materialType: item['materialType'] as String,
            materialName: item['materialName'] as String,
            batchNo: item['batchNo'] as String?,
            packing: item['packing'] as String?,
            quantity: item['quantity'] as int,
            qtyCase: item['qtyCase'] as int? ?? 0,
            rate: (item['rate'] as num).toDouble(),
            discountPercent: (item['discountPercent'] as num).toDouble(),
            discountAmount: (item['discountAmount'] as num).toDouble(),
            taxPercent: (item['taxPercent'] as num).toDouble(),
            taxAmount: (item['taxAmount'] as num).toDouble(),
            amount: (item['amount'] as num).toDouble(),
          ),
        )
        .toList();

    return CreateSaleRequest(
      billNo: json['billNo'] as String,
      customerId: json['customerId'] as String?,
      payMode: json['payMode'] as String,
      taxableValue: (json['taxableValue'] as num).toDouble(),
      totalDiscount: (json['totalDiscount'] as num).toDouble(),
      totalTax: (json['totalTax'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      balanceDue: (json['balanceDue'] as num).toDouble(),
      lineItems: items,
    );
  }

  /// yyyy-MM-dd of the sale's local day — the server keeps it, so a bill
  /// synced days later still lands on the day it was sold.
  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
