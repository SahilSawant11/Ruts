// A busy store day, compressed into seconds. Runs on Windows in CI.
//
// 2,000 sales from a deterministic random stream, with partial and full
// returns, mid-day stock purchases, a backup and a restore. At the end
// every material's stock must reconcile exactly against the bills, every
// bill number must be unique and gap-free, and the restored backup must be
// a healthy, openable Caskly database.
import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/core/local/backup_service.dart';
import 'package:pos_app/core/network/api_exception.dart';
import 'package:pos_app/features/purchase/data/models/create_purchase_request.dart';

import 'support/test_env.dart';

const _materials = 60;
const _sales = 2000;
const _openingStock = 120;

void main() {
  test('simulated busy day reconciles exactly', () async {
    final env = await TestEnv.create();
    final rng = Random(20261101);
    final sw = Stopwatch()..start();

    final ids = [for (var i = 1; i <= _materials; i++) 'M$i'];
    for (final id in ids) {
      await env.addMaterial(id, stock: _openingStock);
    }

    final expected = {for (final id in ids) id: _openingStock};
    final billIds = <String>[];
    final billNos = <String>[];
    var rejected = 0;
    var returns = 0;
    var purchases = 0;
    File? middayBackup;
    Map<String, int>? stockAtBackup;

    for (var i = 0; i < _sales; i++) {
      // A basket of 1–4 distinct items, 1–3 bottles each.
      final basket = <String, int>{};
      final lines = 1 + rng.nextInt(4);
      while (basket.length < lines) {
        basket[ids[rng.nextInt(ids.length)]] = 1 + rng.nextInt(3);
      }

      final canSell = basket.entries.every((e) => expected[e.key]! >= e.value);
      try {
        final r = await env.sales.createSale(TestEnv.sale(basket, payMode: i.isEven ? 'Cash' : 'UPI'));
        expect(canSell, isTrue, reason: 'sale ${r.billNo} should have been rejected');
        basket.forEach((id, q) => expected[id] = expected[id]! - q);
        billIds.add(r.id);
        billNos.add(r.billNo);
      } on ApiException {
        expect(canSell, isFalse, reason: 'sale $i rejected despite enough stock');
        rejected++;
      }

      // ~3% of the time, a customer returns part of a recent bill.
      if (billIds.isNotEmpty && rng.nextInt(100) < 3) {
        final billId = billIds[max(0, billIds.length - 1 - rng.nextInt(min(20, billIds.length)))];
        final lineRows = await (env.db.select(env.db.cachedSaleLineItems)..where((t) => t.salesBillId.equals(billId))).get();
        if (lineRows.isNotEmpty) {
          final line = lineRows[rng.nextInt(lineRows.length)];
          final qty = 1 + rng.nextInt(line.quantity);
          await env.sales.returnSalesBill(billId, lineQuantities: {line.lineNumber: qty});
          expected[line.materialId!] = expected[line.materialId!]! + qty;
          returns++;
        }
      }

      // Every 250 sales a delivery arrives for the 10 lowest-stock items.
      if (i % 250 == 249) {
        final low = (expected.entries.toList()..sort((a, b) => a.value.compareTo(b.value))).take(10).toList();
        await env.purchases.createPurchase(CreatePurchaseRequest(
          supplierId: 'SUP-1',
          billNo: 'INV-$i',
          payMode: 'Credit',
          discount: 0,
          vat: 0,
          stamp: 0,
          tcs: 0,
          loadingFreight: 0,
          netAmount: 0,
          totalAmount: 0,
          lineItems: [
            for (final e in low)
              CreatePurchaseLineItemRequest(
                materialId: e.key,
                batchNo: 'B$i',
                qty: 48,
                rate: 60,
                disPercent: 0,
                disAmount: 0,
                taxPercent: 0,
                taxAmount: 0,
                amount: 48 * 60,
              ),
          ],
        ));
        for (final e in low) {
          expected[e.key] = expected[e.key]! + 48;
        }
        purchases++;
      }

      if (i == _sales ~/ 2) {
        middayBackup = await BackupService(env.db).backupNow();
        stockAtBackup = Map.of(expected);
      }
    }

    // ── Reconcile ────────────────────────────────────────────────────
    for (final id in ids) {
      expect(await env.stockOf(id), expected[id], reason: 'stock mismatch for $id');
      expect(await env.stockOf(id), greaterThanOrEqualTo(0));
    }

    expect(billNos.toSet().length, billNos.length, reason: 'duplicate bill numbers');
    final seqs = billNos.map((b) => int.parse(b.split('-').last)).toList();
    expect(seqs, List.generate(seqs.length, (i) => i + 1), reason: 'bill numbers must be gap-free');

    final queued = await (env.db.select(env.db.syncQueueItems)..where((t) => t.entityType.equals('sale'))).get();
    final fullyReturned = await _fullyReturned(env.db, billIds);
    expect(await env.db.select(env.db.cachedSalesBills).get(), hasLength(billIds.length),
        reason: 'no bill is ever deleted');
    final audit = await env.db.select(env.db.salesReturnEntries).get();
    expect(audit.fold<int>(0, (s, e) => s + e.quantity), greaterThan(0));
    expect(queued.where((q) => q.operation == 'create').length, billIds.length - fullyReturned);

    // ── Restore the midday backup into a fresh database ──────────────
    expect(BackupService.validateBackup(middayBackup!), isNull);
    final restored = AppDatabase(NativeDatabase(middayBackup));
    for (final id in ids) {
      final row = await (restored.select(restored.cachedInventoryStocks)..where((t) => t.materialId.equals(id))).getSingle();
      expect(row.qtyOnHand, stockAtBackup![id], reason: 'backup stock mismatch for $id');
    }
    await restored.close();

    // ignore: avoid_print
    print('Simulated day: ${billIds.length} bills, $rejected rejected for stock, $returns returns, '
        '$purchases deliveries in ${sw.elapsedMilliseconds} ms '
        '(${(sw.elapsedMicroseconds / _sales / 1000).toStringAsFixed(2)} ms per sale incl. checks)');

    await env.dispose();
  }, timeout: const Timeout(Duration(minutes: 10)));
}

/// Fully returned bills stay in the table (status 'returned') but their
/// pending create job is dropped from the sync queue.
Future<int> _fullyReturned(AppDatabase db, List<String> billIds) async {
  final returned = await (db.select(db.cachedSalesBills)
        ..where((t) => t.status.equals(AppDatabase.saleStatusReturned)))
      .get();
  return returned.length;
}
