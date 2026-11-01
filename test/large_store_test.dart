import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';

import 'support/test_env.dart';

/// A store with a lot of history must stay fast on list screens.
void main() {
  test('sales return list: newest 300, search still reaches old bills, fast', () async {
    final env = await TestEnv.create();
    const bills = 2000;
    final start = DateTime(2026, 1, 1);
    await env.db.batch((b) {
      for (var i = 0; i < bills; i++) {
        final id = 'bill-$i';
        final at = start.add(Duration(minutes: i * 30));
        b.insert(env.db.cachedSalesBills, CachedSalesBillsCompanion.insert(
          id: id,
          billNo: 'CS-2526-${(i + 1).toString().padLeft(6, '0')}',
          payMode: 'Cash',
          status: 'paid',
          totalAmount: 100,
          balanceDue: 100,
          totalTax: 0,
          billDate: at,
          createdAt: Value(at),
        ));
        for (var l = 1; l <= 3; l++) {
          b.insert(env.db.cachedSaleLineItems, CachedSaleLineItemsCompanion.insert(
            id: '$id-$l',
            salesBillId: id,
            barcodeNo: 'BC',
            materialType: 'Whisky',
            materialName: 'Item',
            quantity: 1,
            rate: 100,
            discountPercent: 0,
            discountAmount: 0,
            taxPercent: 0,
            taxAmount: 0,
            amount: 100,
            lineNumber: l,
          ));
        }
      }
    });

    final sw = Stopwatch()..start();
    final recent = await env.sales.getSalesBills();
    sw.stop();
    expect(recent, hasLength(300));
    expect(recent.first.billNo, 'CS-2526-002000', reason: 'newest first');
    expect(recent.every((b) => b.lineItems.length == 3), isTrue);
    expect(sw.elapsedMilliseconds, lessThan(1500), reason: 'took ${sw.elapsedMilliseconds}ms');

    final found = await env.sales.getSalesBills(search: '000001');
    expect(found.map((b) => b.billNo), contains('CS-2526-000001'));

    await env.dispose();
  });
}
