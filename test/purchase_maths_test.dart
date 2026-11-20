// Purchase bill maths: line discount/tax, bill discount, VAT, TCS,
// other/breakage, freight, paise rounding, and what a partial purchase
// return leaves on the bill.
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/purchase/data/models/create_purchase_request.dart';
import 'package:pos_app/features/purchase/domain/purchase_line_item.dart';
import 'package:pos_app/features/purchase/presentation/purchase_form_controller.dart';

import 'support/test_env.dart';

PurchaseLineItem _line(int i, int qty, double rate, {double dis = 0, double tax = 0}) => PurchaseLineItem(
    index: i, materialId: 'M$i', manufacturer: 'UB', material: 'Item $i', batch: 'B', packing: '650 ML',
    qty: qty, rate: rate, discountPercent: dis, taxPercent: tax);

CreatePurchaseLineItemRequest _req(PurchaseLineItem l) => CreatePurchaseLineItemRequest(
    materialId: l.materialId, batchNo: l.batch, qty: l.qty, rate: l.rate, disPercent: l.discountPercent,
    disAmount: l.discountAmount, taxPercent: l.taxPercent, taxAmount: l.taxAmount, amount: l.amount);

bool _isPaise(double v) => ((v * 100).round() / 100 - v).abs() < 1e-9;

void main() {
  group('bill maths', () {
    test('line: gross − discount% + tax% on the discounted value', () {
      final l = _line(1, 10, 100, dis: 10, tax: 5);
      expect(l.grossValue, 1000);
      expect(l.discountAmount, 100);
      expect(l.taxableAmount, 900);
      expect(l.taxAmount, 45);
      expect(l.amount, 945);
    });

    test('VAT on (items − discount), TCS on (goods + VAT), other and freight added', () {
      const items = 1000.0;
      const form = PurchaseFormState(discount: 100, vatPercent: 10, tcsPercent: 1, otherCharges: 50, loadingFreight: 25);
      expect(form.vatAmount(items), 90);
      expect(form.tcsAmount(items), 9.9);
      expect(items + form.extraCharges(items), closeTo(1000 + 90 + 9.9 + 50 + 25 - 100, 1e-9));
    });

    test('the net amount is whole paise, even with awkward rates', () {
      final lines = [_line(1, 3, 33.33, dis: 7.5, tax: 2.5), _line(2, 7, 61.17, dis: 3)];
      final items = lines.fold<double>(0, (s, l) => s + l.amount);
      const form = PurchaseFormState(discount: 12.34, vatPercent: 10.5, tcsPercent: 1, otherCharges: 3.33);
      final net = form.netAmount(items);
      expect(_isPaise(net), isTrue, reason: 'net $net');
      expect(net, closeTo(items + form.extraCharges(items), 0.006));
    });

    test('a bill discount bigger than the items is refused', () {
      const form = PurchaseFormState(discount: 1500);
      expect(form.problem(1000), isNotNull);
      expect(const PurchaseFormState(discount: 1000).problem(1000), isNull);
      expect(const PurchaseFormState(discount: -5).problem(1000), isNotNull, reason: 'negative charges');
    });
  });

  group('partial purchase return', () {
    late TestEnv env;
    setUp(() async => env = await TestEnv.create(fileBacked: false));
    tearDown(() async => env.dispose());

    Future<String> buy(List<PurchaseLineItem> lines, PurchaseFormState form) async {
      final items = lines.fold<double>(0, (s, l) => s + l.amount);
      final net = form.netAmount(items);
      final r = await env.purchases.createPurchase(CreatePurchaseRequest(
          supplierId: 'SUP-1', billNo: 'INV-${DateTime.now().microsecondsSinceEpoch}', payMode: 'Credit',
          discount: form.discount, vat: form.vatAmount(items), stamp: form.otherCharges,
          tcs: form.tcsAmount(items), loadingFreight: form.loadingFreight,
          netAmount: net, totalAmount: net, lineItems: [for (final l in lines) _req(l)]));
      return r.id;
    }

    Future<({double net, double vat, double tcs, List<double> lineAmounts})> bill(String id) async {
      final b = await (env.db.select(env.db.cachedPurchaseBills)..where((t) => t.id.equals(id))).getSingle();
      final lines = await (env.db.select(env.db.cachedPurchaseLineItems)..where((t) => t.purchaseBillId.equals(id))).get();
      lines.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
      return (net: b.netAmount, vat: b.vat, tcs: b.tcs, lineAmounts: [for (final l in lines) l.amount]);
    }

    test('the remaining line keeps its discount and tax', () async {
      final id = await buy([_line(1, 10, 100, dis: 10, tax: 5)], const PurchaseFormState());
      await env.purchases.returnPurchaseBill(id, lineQuantities: {1: 4});
      final b = await bill(id);
      expect(b.lineAmounts.single, closeTo(945 * 6 / 10, 0.005), reason: '6 of 10 left at the discounted, taxed price');
      expect(b.net, closeTo(567, 0.005));
    });

    test('VAT and TCS shrink with the goods; other and freight stay', () async {
      // Items 1000; VAT 10% = 100; TCS 1% of 1100 = 11; other 20; freight 10 → 1141.
      const form = PurchaseFormState(vatPercent: 10, tcsPercent: 1, otherCharges: 20, loadingFreight: 10);
      final id = await buy([_line(1, 5, 100), _line(2, 5, 100)], form);
      expect((await bill(id)).net, closeTo(1141, 0.005));

      await env.purchases.returnPurchaseBill(id, lineQuantities: {1: 5});
      final b = await bill(id);
      expect(b.vat, closeTo(50, 0.005));
      expect(b.tcs, closeTo(5.5, 0.005));
      expect(b.net, closeTo(500 + 50 + 5.5 + 20 + 10, 0.005));
    });

    test('with a bill discount, VAT is recomputed on the remaining goods', () async {
      // Items 1000 − discount 100 = 900; VAT 10% = 90 → net 990.
      const form = PurchaseFormState(discount: 100, vatPercent: 10);
      final id = await buy([_line(1, 5, 100), _line(2, 5, 100)], form);
      await env.purchases.returnPurchaseBill(id, lineQuantities: {2: 5});
      final b = await bill(id);
      // 500 left − 100 discount = 400 goods; VAT 40 → 440.
      expect(b.vat, closeTo(40, 0.005));
      expect(b.net, closeTo(440, 0.005));
    });

    test('amounts after a return are whole paise', () async {
      const form = PurchaseFormState(vatPercent: 10.5, tcsPercent: 1);
      final id = await buy([_line(1, 7, 61.17, dis: 3, tax: 2.5), _line(2, 3, 33.33)], form);
      await env.purchases.returnPurchaseBill(id, lineQuantities: {1: 2});
      final b = await bill(id);
      for (final v in [b.net, b.vat, b.tcs, ...b.lineAmounts]) {
        expect(_isPaise(v), isTrue, reason: '$v');
      }
    });
  });
}
