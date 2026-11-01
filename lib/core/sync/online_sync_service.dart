import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../local/app_database.dart';
import '../logging/app_logger.dart';

/// Result of one sync run, for the Settings screen.
class SyncRunResult {
  const SyncRunResult({this.applied = 0, this.duplicates = 0, this.rejected = 0, this.remaining = 0, this.error});

  final int applied;
  final int duplicates;
  final int rejected;
  final int remaining;
  final String? error;

  bool get ok => error == null;

  @override
  String toString() => error ??
      'Sent $applied${duplicates > 0 ? ' (+$duplicates already on server)' : ''}'
          '${rejected > 0 ? ', $rejected need attention' : ''}'
          '${remaining > 0 ? ', $remaining still waiting' : ''}';
}

class SyncException implements Exception {
  const SyncException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Optional online mode: pushes this counter's data to a Caskly server
/// (xoxo API). Nothing happens until an owner connects the counter in
/// Settings — the app stays fully offline-first either way.
///
/// One run:
///  1. Upload master data (and, on first connection, opening stock adjusted
///     for bills still waiting in the queue, so nothing is counted twice).
///  2. Push the queue to /api/sync/push in batches. Each bill is rebuilt from
///     the current local rows, so partial returns made before syncing are
///     reflected. "applied" / "duplicate" items leave the queue; "rejected"
///     ones are marked failed with the server's reason.
class OnlineSyncService {
  OnlineSyncService(this._db, {http.Client? client}) : _http = client ?? http.Client();

  final AppDatabase _db;
  final http.Client _http;

  static const _kUrl = 'sync_server_url';
  static const _kKey = 'sync_device_key';
  static const _kStore = 'sync_store_name';
  static const _kSeeded = 'sync_opening_stock_seeded';
  static const _kLastAt = 'sync_last_at';
  static const _kLastResult = 'sync_last_result';
  static const _batchSize = 100;
  static const _timeout = Duration(seconds: 20);

  bool _running = false;

  // ── Configuration ──────────────────────────────────────────────────

  Future<bool> isConnected() async => (await _db.getSetting(_kKey)) != null && (await _db.getSetting(_kUrl)) != null;
  Future<String?> serverUrl() => _db.getSetting(_kUrl);
  Future<String?> storeName() => _db.getSetting(_kStore);
  Future<String?> lastResult() => _db.getSetting(_kLastResult);

  Future<DateTime?> lastSyncAt() async {
    final raw = await _db.getSetting(_kLastAt);
    return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  }

  /// Registers this counter with the server and stores its API key.
  Future<void> connect({required String serverUrl, required String storeName, required String enrollmentCode}) async {
    final base = normaliseUrl(serverUrl);
    final deviceId = await _db.deviceId();
    final http.Response res;
    try {
      res = await _http
          .post(
            Uri.parse('$base/api/devices/register'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'deviceId': deviceId,
              'deviceName': _deviceName(),
              'storeName': storeName.trim(),
              'enrollmentCode': enrollmentCode.trim(),
            }),
          )
          .timeout(_timeout);
    } on Exception catch (e) {
      throw SyncException('Could not reach the server at $base ($e).');
    }
    if (res.statusCode == 401) throw const SyncException('The enrollment code was not accepted.');
    if (res.statusCode != 200) throw SyncException('Server refused registration (${res.statusCode}): ${_message(res)}');
    final key = (jsonDecode(res.body) as Map<String, dynamic>)['apiKey'] as String?;
    if (key == null) throw const SyncException('Server did not return a device key.');

    await _db.setSetting(_kUrl, base);
    await _db.setSetting(_kKey, key);
    await _db.setSetting(_kStore, storeName.trim());
    AppLogger.info('Sync', 'Connected device $deviceId to $base as "${storeName.trim()}"');
  }

  /// Forgets the server. Queued items stay queued.
  Future<void> disconnect() async {
    for (final k in const [_kUrl, _kKey, _kStore, _kLastAt, _kLastResult]) {
      await _db.deleteSetting(k);
    }
  }

  static String normaliseUrl(String url) {
    var u = url.trim();
    if (!u.startsWith('http://') && !u.startsWith('https://')) u = 'http://$u';
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  // ── Sync run ───────────────────────────────────────────────────────

  Future<SyncRunResult> syncNow() async {
    if (_running) return const SyncRunResult(error: 'A sync is already running.');
    _running = true;
    try {
      final base = await _db.getSetting(_kUrl);
      final key = await _db.getSetting(_kKey);
      if (base == null || key == null) return const SyncRunResult(error: 'This counter is not connected to a server.');
      final headers = {
        'Content-Type': 'application/json',
        'X-Device-Id': await _db.deviceId(),
        'X-Device-Key': key,
      };

      await _pushMasters(base, headers);
      final result = await _pushQueue(base, headers);
      await _db.setSetting(_kLastAt, DateTime.now().toUtc().toIso8601String());
      await _db.setSetting(_kLastResult, result.toString());
      return result;
    } on SyncException catch (e) {
      await _db.setSetting(_kLastResult, 'Failed: ${e.message}');
      AppLogger.warn('Sync', e.message);
      return SyncRunResult(error: e.message);
    } finally {
      _running = false;
    }
  }

  Future<void> _pushMasters(String base, Map<String, String> headers) async {
    final seeded = await _db.getSetting(_kSeeded) != null;
    final body = {
      'categories': [
        for (final c in await _db.select(_db.cachedCategories).get()) {'name': c.name, 'description': c.description},
      ],
      'manufacturers': [
        for (final m in await _db.select(_db.cachedManufacturers).get()) {'name': m.name, 'description': m.description},
      ],
      'packings': [
        for (final p in await _db.select(_db.cachedPackings).get()) {'name': p.name, 'description': p.description},
      ],
      'licenseHolders': [
        for (final h in await _db.select(_db.cachedLicenseHolders).get())
          {'permitNo': h.permitNo, 'name': h.name, 'issuedDate': h.issuedDate, 'whereGranted': h.whereGranted},
      ],
      'materials': [
        for (final m in await _db.select(_db.cachedMaterials).get())
          {
            'id': m.id,
            'barcode': m.barcode,
            'name': m.name,
            'category': m.category,
            'packing': m.packing,
            'saleRate': m.saleRate,
            'taxPercent': m.taxPercent,
            'manufacturer': m.manufacturer,
            'isActive': m.isActive,
          },
      ],
      'suppliers': [
        for (final s in await _db.select(_db.cachedSuppliers).get())
          {
            'clientId': s.id,
            'name': s.name,
            'address': s.address,
            'contactNo': s.contactNo,
            'email': s.email,
            'vatNo': s.vatNo,
            'bankDetails': s.bankDetails,
            'disPercent': s.disPercent,
            'openingBalance': s.openingBalance,
            'balanceType': s.balanceType,
          },
      ],
      if (!seeded) 'openingStock': await openingStockForServer(),
    };
    final res = await _post(base, '/api/sync/masters', headers, body);
    final errors = (jsonDecode(res.body) as Map<String, dynamic>)['errors'] as List<dynamic>? ?? const [];
    for (final e in errors) {
      AppLogger.warn('Sync', 'Master data: $e');
    }
    if (!seeded) await _db.setSetting(_kSeeded, DateTime.now().toUtc().toIso8601String());
  }

  /// Stock the server should start from: what's on hand now, plus sales
  /// still in the queue, minus purchases still in the queue — because the
  /// server will apply those queued bills itself when they're pushed.
  Future<List<Map<String, dynamic>>> openingStockForServer() async {
    final adjust = <String, int>{};
    final pending = await (_db.select(_db.syncQueueItems)
          ..where((t) => t.operation.equals('create') & t.status.isIn(const ['pending', 'failed'])))
        .get();
    for (final item in pending) {
      if (item.entityType == 'sale') {
        final lines = await (_db.select(_db.cachedSaleLineItems)..where((t) => t.salesBillId.equals(item.entityId))).get();
        for (final l in lines) {
          if (l.materialId != null) adjust[l.materialId!] = (adjust[l.materialId!] ?? 0) + l.quantity;
        }
      } else if (item.entityType == 'purchase') {
        final lines =
            await (_db.select(_db.cachedPurchaseLineItems)..where((t) => t.purchaseBillId.equals(item.entityId))).get();
        for (final l in lines) {
          adjust[l.materialId] = (adjust[l.materialId] ?? 0) - l.qty;
        }
      }
    }
    return [
      for (final s in await _db.select(_db.cachedInventoryStocks).get())
        {'materialId': s.materialId, 'qtyOnHand': s.qtyOnHand + (adjust[s.materialId] ?? 0), 'reorderLevel': s.reorderLevel},
    ];
  }

  Future<SyncRunResult> _pushQueue(String base, Map<String, String> headers) async {
    var applied = 0, duplicates = 0, rejected = 0;
    while (true) {
      final rows = await (_db.select(_db.syncQueueItems)
            ..where((t) => t.status.equals('pending') & t.entityType.isIn(const ['sale', 'purchase']))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt), (t) => OrderingTerm.asc(t.id)])
            ..limit(_batchSize))
          .get();
      if (rows.isEmpty) break;

      final items = <Map<String, dynamic>>[];
      final byClientId = <String, SyncQueueItem>{};
      for (final row in rows) {
        final item = await buildSyncItem(row);
        if (item == null) {
          // The bill no longer exists locally; nothing to send.
          await (_db.delete(_db.syncQueueItems)..where((t) => t.id.equals(row.id))).go();
          continue;
        }
        items.add(item);
        byClientId[item['clientId'] as String] = row;
      }
      if (items.isEmpty) continue;

      final res = await _post(base, '/api/sync/push', headers, {'items': items});
      final results = (jsonDecode(res.body) as Map<String, dynamic>)['results'] as List<dynamic>;
      for (final r in results.cast<Map<String, dynamic>>()) {
        final row = byClientId[r['clientId']];
        if (row == null) continue;
        switch (r['status']) {
          case 'applied':
          case 'duplicate':
            r['status'] == 'applied' ? applied++ : duplicates++;
            await _markSynced(row);
          default:
            rejected++;
            await (_db.update(_db.syncQueueItems)..where((t) => t.id.equals(row.id))).write(SyncQueueItemsCompanion(
                  status: const Value('failed'),
                  lastError: Value('${r['error'] ?? 'Rejected by server'}'),
                  updatedAt: Value(DateTime.now().toUtc()),
                ));
            AppLogger.warn('Sync', 'Rejected ${row.entityType} ${row.entityId}: ${r['error']}');
        }
      }
    }
    final remaining = await (_db.selectOnly(_db.syncQueueItems)..addColumns([_db.syncQueueItems.id.count()]))
        .map((r) => r.read(_db.syncQueueItems.id.count()) ?? 0)
        .getSingle();
    return SyncRunResult(applied: applied, duplicates: duplicates, rejected: rejected, remaining: remaining);
  }

  Future<void> _markSynced(SyncQueueItem row) async {
    await (_db.delete(_db.syncQueueItems)..where((t) => t.id.equals(row.id))).go();
    if (row.operation != 'create') return;
    if (row.entityType == 'sale') {
      await (_db.update(_db.cachedSalesBills)..where((t) => t.id.equals(row.entityId)))
          .write(const CachedSalesBillsCompanion(syncStatus: Value('synced')));
    } else {
      await (_db.update(_db.cachedPurchaseBills)..where((t) => t.id.equals(row.entityId)))
          .write(const CachedPurchaseBillsCompanion(syncStatus: Value('synced')));
    }
  }

  /// Builds the /api/sync/push item for a queue row from the CURRENT local
  /// bill (so partial returns are reflected). Null if the bill is gone.
  Future<Map<String, dynamic>?> buildSyncItem(SyncQueueItem row) async {
    if (row.operation == 'return') {
      return {
        'clientId': '${row.entityId}:return',
        'entityType': row.entityType,
        'operation': 'return',
        'payload': {'id': row.entityId},
      };
    }
    final stored = jsonDecode(row.payload) as Map<String, dynamic>;
    if (row.entityType == 'sale') {
      final bill = await (_db.select(_db.cachedSalesBills)..where((t) => t.id.equals(row.entityId))).getSingleOrNull();
      if (bill == null || bill.status == AppDatabase.saleStatusReturned) return null;
      final lines = await (_db.select(_db.cachedSaleLineItems)
            ..where((t) => t.salesBillId.equals(bill.id))
            ..orderBy([(t) => OrderingTerm.asc(t.lineNumber)]))
          .get();
      return {
        'clientId': row.entityId,
        'entityType': 'sale',
        'operation': 'create',
        'payload': {
          ...stored,
          'billNo': bill.billNo,
          'billDate': stored['billDate'] ?? _isoDate(bill.billDate),
          'customerId': null, // local customers are not synced yet
          'totalAmount': bill.totalAmount,
          'totalTax': bill.totalTax,
          'taxableValue': bill.totalAmount - bill.totalTax,
          'lineItems': [
            for (final l in lines)
              {
                'materialId': l.materialId,
                'barcodeNo': l.barcodeNo,
                'materialType': l.materialType,
                'materialName': l.materialName,
                'batchNo': l.batchNo,
                'packing': l.packing,
                'quantity': l.quantity,
                'qtyCase': l.qtyCase,
                'rate': l.rate,
                'discountPercent': l.discountPercent,
                'discountAmount': l.discountAmount,
                'taxPercent': l.taxPercent,
                'taxAmount': l.taxAmount,
                'amount': l.amount,
              },
          ],
        },
      };
    }
    final bill = await (_db.select(_db.cachedPurchaseBills)..where((t) => t.id.equals(row.entityId))).getSingleOrNull();
    if (bill == null || bill.returnedAt != null) return null;
    final lines = await (_db.select(_db.cachedPurchaseLineItems)
          ..where((t) => t.purchaseBillId.equals(bill.id))
          ..orderBy([(t) => OrderingTerm.asc(t.lineNumber)]))
        .get();
    return {
      'clientId': row.entityId,
      'entityType': 'purchase',
      'operation': 'create',
      'payload': {
        ...stored,
        'supplierId': bill.supplierId,
        'tpDate': toIsoDate(bill.tpDate),
        'billDate': stored['billDate'] ?? _isoDate(bill.billDate),
        'netAmount': bill.netAmount,
        'totalAmount': bill.totalAmount,
        'lineItems': [
          for (final l in lines)
            {
              'materialId': l.materialId,
              'batchNo': l.batchNo,
              'packing': l.packing,
              'qty': l.qty,
              'rate': l.rate,
              'disPercent': l.disPercent,
              'disAmount': l.disAmount,
              'taxPercent': l.taxPercent,
              'taxAmount': l.taxAmount,
              'amount': l.amount,
            },
        ],
      },
    };
  }

  Future<http.Response> _post(String base, String path, Map<String, String> headers, Object body) async {
    final http.Response res;
    try {
      res = await _http.post(Uri.parse('$base$path'), headers: headers, body: jsonEncode(body)).timeout(_timeout);
    } on Exception catch (e) {
      throw SyncException('Server unreachable ($e). Data stays queued and will be sent later.');
    }
    if (res.statusCode == 401) throw const SyncException('Server rejected this counter\'s key. Reconnect in Settings.');
    if (res.statusCode >= 400) throw SyncException('Server error ${res.statusCode}: ${_message(res)}');
    return res;
  }

  static String _message(http.Response res) {
    try {
      final j = jsonDecode(res.body);
      if (j is Map && j['message'] != null) return '${j['message']}';
      if (j is Map && j['detail'] != null) return '${j['detail']}';
    } catch (_) {}
    return res.reasonPhrase ?? 'unknown error';
  }

  static String _deviceName() {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'Counter';
    }
  }

  static String _isoDate(DateTime d) {
    final l = d.toLocal();
    return '${l.year.toString().padLeft(4, '0')}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
  }

  /// "01-Nov-2026" / "2026-11-01" / "01/11/2026" → "2026-11-01"; else null.
  static String? toIsoDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.trim();
    final iso = DateTime.tryParse(s);
    if (iso != null) return _isoDate(iso);
    const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    final m = RegExp(r'^(\d{1,2})[-/ ]([A-Za-z]{3}|\d{1,2})[-/ ](\d{4})$').firstMatch(s);
    if (m == null) return null;
    final day = int.parse(m.group(1)!);
    final monthPart = m.group(2)!;
    final month = int.tryParse(monthPart) ?? (months.indexOf(monthPart.toLowerCase()) + 1);
    if (month < 1 || month > 12) return null;
    return _isoDate(DateTime(int.parse(m.group(3)!), month, day));
  }
}
