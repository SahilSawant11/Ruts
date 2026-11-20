// Sales money: the master's discount on each line, tax, paise rounding,
// payment mode on the saved bill, and what a partial return leaves.
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/sales/data/models/create_sale_request.dart';
import 'package:pos_app/features/sales/data/models/material_dto.dart';
import 'package:pos_app/features/sales/presentation/cart_controller.dart';

import 'support/test_env.dart';

MaterialDto _m(String id, double rate, {double dis = 0, double tax = 0, int stock = 50}) => MaterialDto(
    id: id, barcode: 'BC-$id', name: 'Item $id', manufacturer: 'UB', category: 'Beer', packing: '650 ML',
    saleRate: rate, taxPercent: tax, stockQty: stock, discountPercent: dis);

bool _isPaise(double v) => ((v * 100).round() / 100 - v).abs() < 1e-9;

/// The request the Sales screen builds from the cart (as in SalesCheckoutService).
CreateSaleRequest _request(CartState cart, String payMode) => CreateSaleRequest(
      billNo: 'preview',
      payMode: payMode,
      taxableValue: cart.taxableValue,
      totalDiscount: cart.totalDiscount,
      totalTax: cart.totalTax,
      totalAmount: cart.totalAmount,
      balanceDue: cart.totalAmount,
      lineItems: [
        for (final i in cart.items)
          CreateSaleLineItemRequest(
              materialId: i.materialId, barcodeNo: i.barcode, materialType: i.type, materialName: i.material,
              batchNo: i.batch, packing: i.pack, quantity: i.qty, qtyCase: 0, rate: i.rate,
              discountPercent: i.discountPercent, discountAmount: i.discountAmount, taxPercent: i.taxPercent,
              taxAmount: i.taxAmount, amount: i.amount),
      ],
    );

void main() {
  test('each line takes its discount from the master', () async {
    final items = {'BC-A': _m('A', 185, dis: 5), 'BC-B': _m('B', 210)};
    final cart = CartController((c) => items[c]);
    expect(await cart.addByBarcode('BC-A', qty: 3), isTrue);
    expect(await cart.addByBarcode('BC-B'), isTrue);
    final a = cart.state.items.firstWhere((i) => i.materialId == 'A');
    expect((a.discountPercent, a.discountAmount, a.amount), (5.0, 27.75, 527.25));
    expect(cart.state.totalDiscount, 27.75);
    expect(cart.state.totalAmount, 737.25);
  });

  test('totals are whole paise with awkward rates, discount and tax', () async {
    final items = {'BC-A': _m('A', 33.33, dis: 7.5, tax: 2.5), 'BC-B': _m('B', 61.17, dis: 3, tax: 18)};
    final cart = CartController((c) => items[c]);
    await cart.addByBarcode('BC-A', qty: 3);
    await cart.addByBarcode('BC-B', qty: 7);
    final s = cart.state;
    for (final v in [s.taxableValue, s.totalDiscount, s.totalTax, s.totalAmount, for (final i in s.items) i.amount]) {
      expect(_isPaise(v), isTrue, reason: '$v');
    }
    final sumLines = s.items.fold<double>(0, (t, i) => t + i.amount);
    expect(s.totalAmount, closeTo(sumLines, 1e-9), reason: 'bill total = sum of its lines');
    expect(s.taxableValue + s.totalTax, closeTo(s.totalAmount, 0.005));
  });

  group('saved bill', () {
    late TestEnv env;
    setUp(() async => env = await TestEnv.create(fileBacked: false));
    tearDown(() async => env.dispose());

    test('payment mode and amounts are stored as shown; partial return keeps the discount', () async {
      await env.addMaterial('A', stock: 10);
      await env.addMaterial('B', stock: 10);
      final items = {'BC-A': _m('A', 185, dis: 5), 'BC-B': _m('B', 210)};
      final cart = CartController((c) => items[c]);
      await cart.addByBarcode('BC-A', qty: 3);
      await cart.addByBarcode('BC-B');
      final result = await env.sales.createSale(_request(cart.state, 'UPI'));

      Future<({String payMode, double total})> bill() async {
        final b = await (env.db.select(env.db.cachedSalesBills)..where((t) => t.id.equals(result.id))).getSingle();
        return (payMode: b.payMode, total: b.totalAmount);
      }

      expect(await bill(), (payMode: 'UPI', total: 737.25));

      // One of the three discounted bottles comes back.
      await env.sales.returnSalesBill(result.id, lineQuantities: {1: 1});
      final lines = await (env.db.select(env.db.cachedSaleLineItems)..where((t) => t.salesBillId.equals(result.id))).get();
      final a = lines.firstWhere((l) => l.materialId == 'A');
      expect((a.quantity, a.amount, a.discountAmount), (2, 351.5, 18.5));
      expect((await bill()).total, 561.5);
      final entry = (await env.db.select(env.db.salesReturnEntries).get()).single;
      expect(entry.amount, 175.75, reason: 'refund = one bottle at the discounted price');
      expect(await env.stockOf('A'), 8);
    });

    for (final mode in ['Cash', 'Card', 'UPI']) {
      test('$mode is saved on the bill', () async {
        await env.addMaterial('A', stock: 5);
        final r = await env.sales.createSale(TestEnv.sale({'A': 1}, payMode: mode));
        final b = await (env.db.select(env.db.cachedSalesBills)..where((t) => t.id.equals(r.id))).getSingle();
        expect(b.payMode, mode);
      });
    }
  });
}
