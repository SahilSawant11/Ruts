// Returns count on the day they happen. The day a bill (or TP) was made
// never changes afterwards; the return shows on its own day.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/clock.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/masters/data/models/save_material_request.dart';
import 'package:pos_app/features/purchase/data/models/create_purchase_request.dart';
import 'package:pos_app/features/reports/data/brandwise_excel_exporter.dart';
import 'package:pos_app/features/reports/data/brandwise_report_provider.dart';
import 'package:pos_app/features/reports/data/scm_upload_exporter.dart';

import 'support/test_env.dart';

typedef Day = ({int open, int buy, int sale, int close});

void main() {
  late TestEnv env;
  late ProviderContainer c;
  var clock = DateTime(2026, 11, 16, 10); // Monday
  final mon = DateTime(2026, 11, 16), wed = DateTime(2026, 11, 18), thu = DateTime(2026, 11, 19);

  setUp(() async {
    env = await TestEnv.create(fileBacked: false);
    c = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(env.db)]);
    clock = DateTime(2026, 11, 16, 10); // each test starts on Monday
    AppClock.override = () => clock;
    for (final id in ['A', 'B']) {
      await c.read(mastersRepositoryProvider).createMaterial(SaveMaterialRequest(
          id: id, scmCode: id, barcode: 'BC-$id', name: 'BEER $id', manufacturer: 'UB', category: 'Beer',
          liquorType: 'Strong', packing: '650 ML', saleRate: 100, taxPercent: 0, counterBrandName: ''));
      await env.db.into(env.db.cachedInventoryStocks).insert(CachedInventoryStocksCompanion.insert(
          materialId: id, barcode: 'BC-$id', name: 'BEER $id', category: 'Beer', qtyOnHand: 20));
    }
  });
  tearDown(() async {
    AppClock.override = null;
    c.dispose();
    await env.dispose();
  });

  Future<String> register(DateTime day) async {
    c.read(brandwiseReportDateProvider.notifier).state = day;
    c.invalidate(brandwiseReportProvider);
    return BrandwiseExcelExporter().buildWorkbook(await c.read(brandwiseReportProvider.future));
  }

  Future<Day> row(DateTime day, String name) async {
    c.read(brandwiseReportDateProvider.notifier).state = day;
    c.invalidate(brandwiseReportProvider);
    final r = await c.read(brandwiseReportProvider.future);
    final rows = r.categories.expand((x) => x.items).toList();
    final i = rows.indexWhere((x) => x.brandName == name && !x.isTpContinuation);
    if (i < 0) return (open: 0, buy: 0, sale: 0, close: 0);
    var buy = rows[i].purchase.total;
    for (var k = i + 1; k < rows.length && rows[k].isTpContinuation; k++) {
      buy += rows[k].purchase.total;
    }
    return (open: rows[i].openingBalance.total, buy: buy, sale: rows[i].sale.total, close: rows[i].closingBalance.total);
  }

  test('a sale returned in two goes on later days: Monday never changes', () async {
    final bill = await env.sales.createSale(TestEnv.sale({'A': 5, 'B': 3}));
    final mondayPrinted = await register(mon);
    expect(await row(mon, 'BEER A'), (open: 20, buy: 0, sale: 5, close: 15));

    clock = DateTime(2026, 11, 18, 11); // Wednesday: 2 of A back, and all of B (a whole line)
    await env.sales.returnSalesBill(bill.id, lineQuantities: {1: 2, 2: 3});
    clock = DateTime(2026, 11, 19, 12); // Thursday: the last 3 of A (the bill is now fully returned)
    await env.sales.returnSalesBill(bill.id);

    expect(await register(mon), mondayPrinted, reason: 'Monday\'s register is exactly as printed');
    expect(await row(wed, 'BEER A'), (open: 15, buy: 0, sale: -2, close: 17));
    expect(await row(wed, 'BEER B'), (open: 17, buy: 0, sale: -3, close: 20));
    expect(await row(thu, 'BEER A'), (open: 17, buy: 0, sale: -3, close: 20));
    expect(await env.stockOf('A'), 20);

    // The SCM upload says the same: Monday's sale stands, the returns are on their days.
    final scm = await ScmUploadExporter.rows(env.db, mon, thu);
    int? looseOn(String date, String id) => scm.firstWhere((r) => r[0] == date && r[1] == id)[5] as int?;
    expect(looseOn('11/16/2026', 'A'), 5);
    expect(looseOn('11/16/2026', 'B'), 3);
    expect(looseOn('11/18/2026', 'A'), -2);
    expect(looseOn('11/19/2026', 'A'), -3);
  });

  test('goods sent back days after the TP: the TP\'s day never changes', () async {
    final p = await env.purchases.createPurchase(const CreatePurchaseRequest(
        supplierId: 'SUP-1', billNo: 'INV-1', payMode: 'Credit', tpNo: 'TP-1', discount: 0, vat: 0, stamp: 0, tcs: 0,
        loadingFreight: 0, netAmount: 2400, totalAmount: 2400,
        lineItems: [
          CreatePurchaseLineItemRequest(materialId: 'A', batchNo: 'B', qty: 24, rate: 100, disPercent: 0,
              disAmount: 0, taxPercent: 0, taxAmount: 0, amount: 2400),
        ]));
    final mondayPrinted = await register(mon);
    expect(await row(mon, 'BEER A'), (open: 20, buy: 24, sale: 0, close: 44));

    clock = DateTime(2026, 11, 18, 11); // Wednesday: a broken case of 6 goes back
    await env.purchases.returnPurchaseBill(p.id, lineQuantities: {1: 6});

    expect(await register(mon), mondayPrinted);
    expect(await row(wed, 'BEER A'), (open: 44, buy: -6, sale: 0, close: 38));
    c.read(brandwiseReportDateProvider.notifier).state = wed;
    c.invalidate(brandwiseReportProvider);
    final wedRows = (await c.read(brandwiseReportProvider.future)).categories.expand((x) => x.items);
    expect(wedRows.first.tpNo, 'TP-1', reason: 'the minus row sits under the TP it came on');
    expect(await env.stockOf('A'), 38);

    clock = DateTime(2026, 11, 19, 11); // Thursday: the rest goes back (full return)
    await env.purchases.returnPurchaseBill(p.id);
    expect(await register(mon), mondayPrinted);
    expect(await row(thu, 'BEER A'), (open: 38, buy: -18, sale: 0, close: 20));
    expect(await env.stockOf('A'), 20);
  });
}
