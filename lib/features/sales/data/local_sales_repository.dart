import 'dart:convert';

import 'package:drift/drift.dart' hide Column;

import '../../../core/local/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../masters/data/local_masters_repository.dart';
import 'models/create_sale_request.dart';
import 'models/customer_dto.dart';
import 'models/material_dto.dart';
import 'models/sales_bill_dto.dart';
import 'sales_api_repository.dart';

class LocalSalesRepository {
  LocalSalesRepository(this._db, this._remote, this._masters);

  final AppDatabase _db;
  final SalesApiRepository _remote;
  final LocalMastersRepository _masters;

  Future<List<SalesBillDto>> getTodaysBills() async {
    final queued = await _getQueuedBills();

    try {
      await syncPendingSales();
      final remote = await _remote.getTodaysBills();
      return [...queued, ...remote];
    } on ApiException {
      return queued;
    }
  }

  Future<MaterialDto?> getMaterialByBarcode(String barcode) async {
    try {
      await syncPendingSales();
    } on ApiException {
      // Fall back to local masters cache below.
    }
    return _masters.getMaterialByBarcode(barcode);
  }

  Future<List<CustomerDto>> getCustomers() async {
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

        final request = _decodeRequest(row.payload);
        final syncedRequest = await _resolveDependencies(request);
        await _remote.createSale(syncedRequest);

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

  Future<CreateSaleResult> createSale(CreateSaleRequest request) async {
    try {
      await syncPendingSales();
      final syncedRequest = await _resolveDependencies(request);
      return await _remote.createSale(syncedRequest);
    } on ApiException catch (e) {
      if (e.statusCode != null) rethrow;

      final localId = 'local-sale-${DateTime.now().microsecondsSinceEpoch}';
      await _db.into(_db.syncQueueItems).insert(
            SyncQueueItemsCompanion.insert(
              entityType: 'sale',
              entityId: localId,
              operation: 'create',
              payload: jsonEncode(request.toJson()),
              status: const Value('pending'),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );

      return CreateSaleResult(
        id: localId,
        billNo: request.billNo,
        lineItemCount: request.lineItems.length,
        isPendingSync: true,
      );
    }
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

  Future<List<SalesBillDto>> _getQueuedBills() async {
    final rows = await (_db.select(_db.syncQueueItems)
          ..where((tbl) => tbl.entityType.equals('sale') & tbl.status.isNotValue('failed'))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();

    return rows.map((row) {
      final request = _decodeRequest(row.payload);
      return SalesBillDto(
        id: row.entityId,
        billNo: request.billNo,
        billDate: row.createdAt.toIso8601String(),
        payMode: request.payMode,
        totalAmount: request.totalAmount,
        balanceDue: request.balanceDue,
        status: 'pending sync',
        lineItemCount: request.lineItems.length,
      );
    }).toList();
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
}
