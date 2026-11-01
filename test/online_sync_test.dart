import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/core/sync/online_sync_service.dart';
import 'package:pos_app/features/purchase/data/models/create_purchase_request.dart';

import 'support/test_env.dart';

/// A tiny fake Caskly server recording what the app sends.
class FakeServer {
  final requests = <String, List<Map<String, dynamic>>>{};
  String Function(Map<String, dynamic> item) decide = (_) => 'applied';
  bool down = false;

  late final client = MockClient((req) async {
    if (down) throw const SocketException('connection refused');
    final body = req.body.isEmpty ? <String, dynamic>{} : jsonDecode(req.body) as Map<String, dynamic>;
    requests.putIfAbsent(req.url.path, () => []).add(body);
    switch (req.url.path) {
      case '/api/devices/register':
        if (body['enrollmentCode'] != 'good') return http.Response('{"message":"Invalid enrollment code."}', 401);
        return http.Response(jsonEncode({'deviceId': body['deviceId'], 'storeId': 's1', 'apiKey': 'KEY'}), 200);
      case '/api/sync/masters':
        if (req.headers['X-Device-Key'] != 'KEY') return http.Response('{}', 401);
        return http.Response('{"upserts":1,"openingStockSeeded":1,"errors":[]}', 200);
      case '/api/sync/push':
        final items = (body['items'] as List).cast<Map<String, dynamic>>();
        return http.Response(
          jsonEncode({
            'results': [
              for (final i in items)
                {'clientId': i['clientId'], 'status': decide(i), 'serverId': 'srv-${i['clientId']}', 'error': decide(i) == 'rejected' ? 'Unknown material' : null},
            ],
          }),
          200,
        );
    }
    return http.Response('not found', 404);
  });
}

void main() {
  late TestEnv env;
  late FakeServer server;
  late OnlineSyncService sync;

  setUp(() async {
    env = await TestEnv.create();
    server = FakeServer();
    sync = OnlineSyncService(env.db, client: server.client);
    await env.addMaterial('A', stock: 50);
    await env.addMaterial('B', stock: 50);
  });
  tearDown(() async => env.dispose());

  test('connect rejects a bad enrollment code and stays offline', () async {
    await expectLater(
      sync.connect(serverUrl: 'shop-server:5080/', storeName: 'Test Wines', enrollmentCode: 'bad'),
      throwsA(isA<SyncException>()),
    );
    expect(await sync.isConnected(), isFalse);
  });

  test('full run: masters, then queue; synced bills leave the queue', () async {
    final sale = await env.sales.createSale(TestEnv.sale({'A': 3, 'B': 1}));
    await sync.connect(serverUrl: 'shop-server:5080/', storeName: 'Test Wines', enrollmentCode: 'good');
    expect(await sync.serverUrl(), 'http://shop-server:5080');

    final r = await sync.syncNow();
    expect(r.ok, isTrue, reason: r.toString());
    expect(r.applied, 1);

    // Opening stock adds the still-queued sale back (server will apply it itself).
    final opening = (server.requests['/api/sync/masters']!.first['openingStock'] as List).cast<Map<String, dynamic>>();
    expect(opening.firstWhere((o) => o['materialId'] == 'A')['qtyOnHand'], 50);

    final pushed = (server.requests['/api/sync/push']!.single['items'] as List).single as Map<String, dynamic>;
    expect(pushed['clientId'], sale.id);
    expect(pushed['payload']['billNo'], sale.billNo);
    expect(pushed['payload']['billDate'], isNotNull);

    expect(await env.db.select(env.db.syncQueueItems).get(), isEmpty);
    final bill = await (env.db.select(env.db.cachedSalesBills)..where((t) => t.id.equals(sale.id))).getSingle();
    expect(bill.syncStatus, 'synced');

    // Second run: opening stock is NOT sent again.
    await sync.syncNow();
    expect(server.requests['/api/sync/masters']![1].containsKey('openingStock'), isFalse);
  });

  test('partial return before sync is reflected in what is sent', () async {
    final sale = await env.sales.createSale(TestEnv.sale({'A': 3}));
    await env.sales.returnSalesBill(sale.id, lineQuantities: {1: 2});
    final row = (await env.db.select(env.db.syncQueueItems).get()).single;
    final item = await sync.buildSyncItem(row);
    final line = (item!['payload']['lineItems'] as List).single as Map<String, dynamic>;
    expect(line['quantity'], 1);
    expect(item['payload']['totalAmount'], 100);
  });

  test('server down: nothing lost, bills stay queued', () async {
    await env.sales.createSale(TestEnv.sale({'A': 1}));
    await sync.connect(serverUrl: 'x', storeName: 'S', enrollmentCode: 'good');
    server.down = true;
    final r = await sync.syncNow();
    expect(r.ok, isFalse);
    final queue = await env.db.select(env.db.syncQueueItems).get();
    expect(queue.single.status, 'pending');
  });

  test('rejected items are marked failed with the reason; others still sync', () async {
    final good = await env.sales.createSale(TestEnv.sale({'A': 1}));
    final bad = await env.sales.createSale(TestEnv.sale({'B': 1}));
    server.decide = (i) => i['clientId'] == bad.id ? 'rejected' : 'applied';
    await sync.connect(serverUrl: 'x', storeName: 'S', enrollmentCode: 'good');
    final r = await sync.syncNow();
    expect(r.applied, 1);
    expect(r.rejected, 1);
    final left = (await env.db.select(env.db.syncQueueItems).get()).single;
    expect(left.entityId, bad.id);
    expect(left.status, 'failed');
    expect(left.lastError, 'Unknown material');
    expect(good.id, isNot(bad.id));
  });

  test('full return of a synced bill queues a return for the server', () async {
    final sale = await env.sales.createSale(TestEnv.sale({'A': 2}));
    await sync.connect(serverUrl: 'x', storeName: 'S', enrollmentCode: 'good');
    await sync.syncNow();
    await env.sales.returnSalesBill(sale.id);
    final row = (await env.db.select(env.db.syncQueueItems).get()).single;
    expect(row.operation, 'return');
    final item = await sync.buildSyncItem(row);
    expect(item!['clientId'], '${sale.id}:return');
    expect(item['payload'], {'id': sale.id});
  });

  test('TP dates are normalised to ISO', () {
    expect(OnlineSyncService.toIsoDate('01-Nov-2026'), '2026-11-01');
    expect(OnlineSyncService.toIsoDate('2026-11-01'), '2026-11-01');
    expect(OnlineSyncService.toIsoDate('05/03/2027'), '2027-03-05');
    expect(OnlineSyncService.toIsoDate('soon'), isNull);
  });

  test('builds contract sync items (fixture replayed by the server tests)', () async {
    await env.db.into(env.db.cachedSuppliers).insert(CachedSuppliersCompanion.insert(id: 'SUP-001', name: 'Royal Spirits'));
    final sale = await env.sales.createSale(TestEnv.sale({'A': 2}));
    final purchase = await env.purchases.createPurchase(const CreatePurchaseRequest(
      supplierId: 'SUP-001', billNo: 'INV-1', payMode: 'Credit', tpDate: '01-Nov-2026', discount: 0, vat: 0, stamp: 0,
      tcs: 0, loadingFreight: 0, netAmount: 600, totalAmount: 600,
      lineItems: [CreatePurchaseLineItemRequest(materialId: 'B', batchNo: 'B-1', qty: 12, rate: 50, disPercent: 0, disAmount: 0, taxPercent: 0, taxAmount: 0, amount: 600)],
    ));
    final rows = await env.db.select(env.db.syncQueueItems).get();
    final items = [for (final r in rows) await sync.buildSyncItem(r)];
    expect(items.map((i) => i!['clientId']), containsAll([sale.id, purchase.id]));
    // Regenerate the server's contract fixture only when asked:
    //   UPDATE_SYNC_FIXTURE=1 flutter test test/online_sync_test.dart
    // then copy it to xoxo/Xoxo.Api.Tests/Fixtures/.
    if (Platform.environment['UPDATE_SYNC_FIXTURE'] == '1') {
      File('test/fixtures/sync_push_sample.json')
        ..createSync(recursive: true)
        ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert({'items': items}));
    }
  });
}
