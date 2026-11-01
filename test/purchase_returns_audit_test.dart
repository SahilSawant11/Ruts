import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/network/api_exception.dart';
import 'package:pos_app/features/purchase/data/models/create_purchase_request.dart';

import 'support/test_env.dart';

CreatePurchaseRequest _purchase(Map<String, int> qtyById, {String billNo = 'INV-1'}) {
  final lines = [
    for (final e in qtyById.entries)
      CreatePurchaseLineItemRequest(
        materialId: e.key,
        batchNo: 'B1',
        qty: e.value,
        rate: 50,
        disPercent: 0,
        disAmount: 0,
        taxPercent: 0,
        taxAmount: 0,
        amount: 50.0 * e.value,
      ),
  ];
  final total = lines.fold<double>(0, (s, l) => s + l.amount);
  return CreatePurchaseRequest(
    supplierId: 'SUP-1',
    billNo: billNo,
    payMode: 'Credit',
    discount: 0,
    vat: 0,
    stamp: 0,
    tcs: 0,
    loadingFreight: 0,
    netAmount: total,
    totalAmount: total,
    lineItems: lines,
  );
}

void main() {
  late TestEnv env;
  setUp(() async {
    env = await TestEnv.create();
    await env.addMaterial('A', stock: 0);
    await env.addMaterial('B', stock: 0);
  });
  tearDown(() async => env.dispose());

  test('full purchase return keeps the bill, marks it returned, hides it from lists', () async {
    final p = await env.purchases.createPurchase(_purchase({'A': 12, 'B': 6}));
    expect(await env.stockOf('A'), 12);

    await env.purchases.returnPurchaseBill(p.id, returnedBy: 'admin');

    final bill = await (env.db.select(env.db.cachedPurchaseBills)..where((t) => t.id.equals(p.id))).getSingle();
    expect(bill.returnedAt, isNotNull);
    expect(bill.returnedBy, 'admin');
    expect(bill.totalAmount, 900, reason: 'original figures kept');
    final lines = await (env.db.select(env.db.cachedPurchaseLineItems)..where((t) => t.purchaseBillId.equals(p.id))).get();
    expect(lines.map((l) => l.qty), [12, 6]);

    expect(await env.stockOf('A'), 0);
    expect(await env.stockOf('B'), 0);
    expect(await env.purchases.getPurchaseBills(), isEmpty, reason: 'not offered for return again');

    final audit = await env.db.select(env.db.purchaseReturnEntries).get();
    expect(audit.fold<int>(0, (s, e) => s + e.quantity), 18);
    expect(audit.every((e) => e.isFullBillReturn), isTrue);
    await expectLater(env.purchases.returnPurchaseBill(p.id), throwsA(isA<ApiException>()));
  });

  test('cannot return more than is in stock (already sold)', () async {
    final p = await env.purchases.createPurchase(_purchase({'A': 5}));
    await env.sales.createSale(TestEnv.sale({'A': 4}));

    await expectLater(
      env.purchases.returnPurchaseBill(p.id),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('only 1 in stock'))),
    );
    expect(await env.stockOf('A'), 1, reason: 'refused return changes nothing');
    expect(await env.db.select(env.db.purchaseReturnEntries).get(), isEmpty);

    await env.purchases.returnPurchaseBill(p.id, lineQuantities: {1: 1});
    expect(await env.stockOf('A'), 0);
    final bill = await (env.db.select(env.db.cachedPurchaseBills)..where((t) => t.id.equals(p.id))).getSingle();
    expect(bill.returnedAt, isNull, reason: 'partial return keeps the bill active');
    expect(bill.totalAmount, 200);
  });
}
