// Brandwise reports for past days must show that day's own stock, not
// today's. Three days of sales, a purchase and returns; each day's closing
// must equal the next day's opening, and match what stock really was.
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/purchase/data/models/create_purchase_request.dart';
import 'package:pos_app/features/reports/data/brandwise_report_provider.dart';
import 'package:pos_app/features/reports/data/counter_brandwise_report_provider.dart';
import 'package:pos_app/features/reports/data/models/brandwise_report_dto.dart';

import 'support/test_env.dart';

typedef Day = ({int opening, int purchase, int sale, int closing});

void main() {
  test('each past day reports its own opening and closing stock', () async {
    final env = await TestEnv.create(fileBacked: false);
    addTearDown(env.dispose);
    await env.addMaterial('M1', stock: 100);

    final today = DateUtils.today();
    final d2 = today.subtract(const Duration(days: 2));
    final d1 = today.subtract(const Duration(days: 1));

    Future<String> saleOn(DateTime day, int qty) async {
      final r = await env.sales.createSale(TestEnv.sale({'M1': qty}));
      await (env.db.update(env.db.cachedSalesBills)..where((t) => t.id.equals(r.id)))
          .write(CachedSalesBillsCompanion(billDate: Value(day.add(const Duration(hours: 13)))));
      return r.id;
    }

    // Day -2: open 100, sell 5 + 10 (one bill later partly returned: 10 → 7).
    await saleOn(d2, 5);
    final partly = await saleOn(d2, 10);
    // Day -1: delivery of 24, sell 3, and a bill that is later fully returned.
    await env.purchases.createPurchase(CreatePurchaseRequest(
      supplierId: 'SUP-1', billNo: 'INV-1', payMode: 'Credit', discount: 0, vat: 0, stamp: 0, tcs: 0,
      loadingFreight: 0, netAmount: 0, totalAmount: 0,
      lineItems: const [
        CreatePurchaseLineItemRequest(
            materialId: 'M1', batchNo: 'B1', qty: 24, rate: 60, disPercent: 0, disAmount: 0,
            taxPercent: 0, taxAmount: 0, amount: 24 * 60),
      ],
    ));
    final purchaseBill = await (env.db.select(env.db.cachedPurchaseBills)).getSingle();
    await (env.db.update(env.db.cachedPurchaseBills)..where((t) => t.id.equals(purchaseBill.id)))
        .write(CachedPurchaseBillsCompanion(billDate: Value(d1.add(const Duration(hours: 10)))));
    await saleOn(d1, 3);
    final undone = await saleOn(d1, 6);
    // Today: sell 4. Returns happen today but belong to their bills' days.
    await saleOn(today, 4);
    final lines = await (env.db.select(env.db.cachedSaleLineItems)..where((t) => t.salesBillId.equals(partly))).get();
    await env.sales.returnSalesBill(partly, lineQuantities: {lines.single.lineNumber: 3});
    await env.sales.returnSalesBill(undone);

    // Real stock: 100 − 5 − 7 = 88 → +24 − 3 = 109 → −4 = 105.
    expect(await env.stockOf('M1'), 105);

    final container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(env.db)]);
    addTearDown(container.dispose);

    Future<Day> brandwise(DateTime day) async {
      container.read(brandwiseReportDateProvider.notifier).state = day;
      final r = await container.read(brandwiseReportProvider.future);
      final i = r.categories.expand((c) => c.items).single;
      return (opening: i.openingBalance.total, purchase: i.purchase.total, sale: i.sale.total, closing: i.closingBalance.total);
    }

    Future<Day> counter(DateTime day) async {
      container.read(counterBrandwiseReportDateProvider.notifier).state = day;
      final r = await container.read(counterBrandwiseReportProvider.future);
      final i = r.categories.expand((c) => c.items).single;
      return (opening: i.openingBalance.total, purchase: i.purchase.total, sale: i.sale.total, closing: _closing(i));
    }

    for (final report in [brandwise, counter]) {
      expect(await report(d2), (opening: 100, purchase: 0, sale: 12, closing: 88));
      expect(await report(d1), (opening: 88, purchase: 24, sale: 3, closing: 109));
      expect(await report(today), (opening: 109, purchase: 0, sale: 4, closing: 105));
    }
  });
}

int _closing(dynamic item) => (item.closingBalance as BrandwiseSizeQty).total;

abstract final class DateUtils {
  static DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}
