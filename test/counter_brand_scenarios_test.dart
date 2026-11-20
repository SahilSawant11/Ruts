// Counter brand scenarios: several drinks and sizes under one counter
// brand are separate rows in Brandwise and one line in Counter Brandwise,
// with every column (opening, purchase per TP, sale, closing) adding up,
// and the Excel file matching the screen.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/masters/data/models/save_material_request.dart';
import 'package:pos_app/features/purchase/data/models/create_purchase_request.dart';
import 'package:pos_app/features/reports/data/brandwise_report_provider.dart';
import 'package:pos_app/features/reports/data/counter_brandwise_excel_exporter.dart';
import 'package:pos_app/features/reports/data/counter_brandwise_report_provider.dart';
import 'package:pos_app/features/reports/data/models/brandwise_report_dto.dart';
import 'package:pos_app/features/reports/data/models/counter_brandwise_report_dto.dart';

import 'support/test_env.dart';

SaveMaterialRequest _mat(String id, String name, String packing, String counter, {String type = 'Strong'}) =>
    SaveMaterialRequest(
        id: id, scmCode: id, barcode: 'BC$id', name: name, manufacturer: 'UB', category: 'Beer',
        liquorType: type, packing: packing, saleRate: 100, taxPercent: 0, counterBrandName: counter);

/// Columns: 3 = 650, 4 = 500 CAN, 5 = 330 CAN, 7 = first extra (1000ml).
List<int> _cols(BrandwiseSizeQty q, List<String> extras) => [for (var i = 0; i < 7 + extras.length; i++) q.at(i, extras)];

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  late TestEnv env;
  late ProviderContainer c;
  setUp(() async {
    env = await TestEnv.create(fileBacked: false);
    c = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(env.db)]);
  });
  tearDown(() async {
    c.dispose();
    await env.dispose();
  });

  var billSeq = 0;
  Future<void> buy(Map<String, int> lines, String tp) => env.purchases.createPurchase(CreatePurchaseRequest(
        supplierId: 'SUP-1', billNo: 'INV-${++billSeq}', payMode: 'Credit', tpNo: tp,
        discount: 0, vat: 0, stamp: 0, tcs: 0, loadingFreight: 0, netAmount: 0, totalAmount: 0,
        lineItems: [
          for (final e in lines.entries)
            CreatePurchaseLineItemRequest(materialId: e.key, batchNo: 'B', qty: e.value, rate: 100, disPercent: 0,
                disAmount: 0, taxPercent: 0, taxAmount: 0, amount: e.value * 100.0),
        ],
      ));

  Future<void> openingStock(String id, int qty) => env.db.into(env.db.cachedInventoryStocks).insert(
      CachedInventoryStocksCompanion.insert(materialId: id, barcode: 'BC$id', name: id, category: 'Beer', qtyOnHand: qty));

  /// The full shop day used by every test below.
  Future<void> shopDay() async {
    final repo = c.read(mastersRepositoryProvider);
    // One counter brand, four drinks, four sizes, three spellings.
    await repo.createMaterial(_mat('K650', 'KF STRONG 650', '650 ML', 'Kingfisher Strong'));
    await repo.createMaterial(_mat('K500', 'KF STRONG 500 CAN', '500 ML (CAN)', 'kingfisher strong'));
    await repo.createMaterial(_mat('K330', 'KF SUPER STRONG 330 CAN', '330 ML (CAN)', '  Kingfisher   STRONG '));
    await repo.createMaterial(_mat('K1000', 'KF STRONG TOWER', '1000 ML', 'Kingfisher Strong'));
    // Another brand in the same section, and the same counter brand in Mild.
    await repo.createMaterial(_mat('T650', 'TUBORG STRONG', '650 ML', ''));
    await repo.createMaterial(_mat('KM650', 'KF MILD 650', '650 ML', 'Kingfisher Strong', type: 'Mild'));

    await openingStock('K650', 24);
    await openingStock('K500', 12);

    await buy({'K650': 10, 'K500': 6, 'T650': 5}, 'TP-A');
    await buy({'K330': 4, 'K1000': 3, 'K650': 2}, 'TP-B');
    await buy({'KM650': 6}, 'TP-C');

    final s1 = await env.sales.createSale(TestEnv.sale({'K650': 3, 'K500': 2, 'K330': 1}));
    await env.sales.createSale(TestEnv.sale({'K1000': 1, 'T650': 2, 'KM650': 1}));
    // One 650 comes back: net sale of 650 is 2.
    await env.sales.returnSalesBill(s1.id, lineQuantities: {1: 1});
  }

  Future<CounterBrandwiseReportDto> counter() {
    c.invalidate(counterBrandwiseReportProvider);
    return c.read(counterBrandwiseReportProvider.future);
  }

  Future<BrandwiseReportDto> brandwise() {
    c.invalidate(brandwiseReportProvider);
    return c.read(brandwiseReportProvider.future);
  }

  List<CounterBrandwiseReportItemDto> linesFor(CounterBrandwiseReportDto r, String section, String brand) =>
      r.categories.firstWhere((x) => x.name == section).items.where((i) => _norm(i.manufacturerName) == _norm(brand)).toList();

  test('1. one counter line for four drinks; every column adds up', () async {
    await shopDay();
    final r = await counter();
    expect(r.extraSizes, ['1000ml']);
    final kf = linesFor(r, 'STRONG BEER', 'Kingfisher Strong');
    expect(kf.length, 2, reason: 'one line + one extra TP row');
    final first = kf[0], tpB = kf[1];
    final x = r.extraSizes;

    //                          750 375 180 650 500c 330c 330 1000
    expect(_cols(first.openingBalance, x), [0, 0, 0, 24, 12, 0, 0, 0], reason: 'opening');
    expect(first.tpNo, 'TP-A');
    expect(_cols(first.purchase, x), [0, 0, 0, 10, 6, 0, 0, 0], reason: 'TP-A purchase');
    expect(tpB.tpNo, 'TP-B');
    expect(tpB.isTpContinuation, isTrue);
    expect(_cols(tpB.purchase, x), [0, 0, 0, 2, 0, 4, 0, 3], reason: 'TP-B purchase');
    expect(_cols(tpB.sale, x).every((v) => v == 0), isTrue, reason: 'TP row carries purchase only');
    expect(_cols(first.sale, x), [0, 0, 0, 2, 2, 1, 0, 1], reason: 'sale (one 650 returned)');
    expect(_cols(first.closingBalance, x), [0, 0, 0, 34, 16, 3, 0, 2], reason: 'closing');
  });

  test('2. opening + purchase − sale = closing in every column', () async {
    await shopDay();
    final r = await counter();
    final x = r.extraSizes;
    for (final cat in r.categories) {
      final names = cat.items.where((i) => !i.isTpContinuation).map((i) => i.manufacturerName);
      for (final name in names) {
        final rows = cat.items.where((i) => i.manufacturerName == name).toList();
        for (var col = 0; col < 7 + x.length; col++) {
          final open = rows.first.openingBalance.at(col, x);
          final buy = rows.fold<int>(0, (s, i) => s + i.purchase.at(col, x));
          final sold = rows.first.sale.at(col, x);
          final close = rows.first.closingBalance.at(col, x);
          expect(open + buy - sold, close, reason: '${cat.name} / $name, column $col');
        }
      }
    }
  });

  test('3. Brandwise keeps the drinks separate and they sum to the counter line', () async {
    await shopDay();
    final b = await brandwise();
    final r = await counter();
    expect(b.extraSizes, r.extraSizes);
    final x = r.extraSizes;
    final strong = b.categories.firstWhere((cat) => cat.name == 'STRONG BEER').items;
    final names = strong.where((i) => !i.isTpContinuation).map((i) => i.brandName).toSet();
    expect(names, {'KF STRONG 650', 'KF STRONG 500 CAN', 'KF SUPER STRONG 330 CAN', 'KF STRONG TOWER', 'TUBORG STRONG'});

    final kfRows = strong.where((i) => i.brandName.startsWith('KF') || i.isTpContinuation).toList();
    // Continuation rows belong to the brand above them.
    final kfOnly = <BrandwiseReportItemDto>[];
    var inKf = false;
    for (final i in strong) {
      if (!i.isTpContinuation) inKf = i.brandName.startsWith('KF');
      if (inKf) kfOnly.add(i);
    }
    expect(kfRows.length, greaterThanOrEqualTo(kfOnly.length));
    final counterRows = linesFor(r, 'STRONG BEER', 'Kingfisher Strong');
    for (final (label, ofB, ofC) in [
      ('opening', (BrandwiseReportItemDto i) => i.openingBalance, (CounterBrandwiseReportItemDto i) => i.openingBalance),
      ('purchase', (BrandwiseReportItemDto i) => i.purchase, (CounterBrandwiseReportItemDto i) => i.purchase),
      ('sale', (BrandwiseReportItemDto i) => i.sale, (CounterBrandwiseReportItemDto i) => i.sale),
      ('closing', (BrandwiseReportItemDto i) => i.closingBalance, (CounterBrandwiseReportItemDto i) => i.closingBalance),
    ]) {
      for (var col = 0; col < 7 + x.length; col++) {
        final sumB = kfOnly.fold<int>(0, (s, i) => s + ofB(i).at(col, x));
        final sumC = counterRows.fold<int>(0, (s, i) => s + ofC(i).at(col, x));
        expect(sumC, sumB, reason: '$label column $col');
      }
    }
    // Section subtotals agree too.
    final bSub = b.categories.firstWhere((cat) => cat.name == 'STRONG BEER').subtotal;
    final cSub = r.categories.firstWhere((cat) => cat.name == 'STRONG BEER').subtotal;
    expect(_cols(cSub.openingBalance, x), _cols(bSub.openingBalance, x));
    expect(_cols(cSub.purchase, x), _cols(bSub.purchase, x));
    expect(_cols(cSub.sale, x), _cols(bSub.sale, x));
    expect(_cols(cSub.closingBalance, x), _cols(bSub.closingBalance, x));
  });

  test('4. another brand stays its own line', () async {
    await shopDay();
    final r = await counter();
    final t = linesFor(r, 'STRONG BEER', 'TUBORG STRONG');
    expect(t.length, 1);
    expect(_cols(t.single.purchase, r.extraSizes)[3], 5);
    expect(_cols(t.single.sale, r.extraSizes)[3], 2);
    expect(_cols(t.single.closingBalance, r.extraSizes)[3], 3);
    expect(t.single.tpNo, 'TP-A');
  });

  test('5. the same counter brand in Mild stays in the Mild section', () async {
    await shopDay();
    final r = await counter();
    final mild = linesFor(r, 'MILD BEER', 'Kingfisher Strong');
    expect(mild.length, 1);
    expect(_cols(mild.single.purchase, r.extraSizes)[3], 6);
    expect(_cols(mild.single.closingBalance, r.extraSizes)[3], 5);
    // …and does not leak into the Strong line.
    final strong650Close = linesFor(r, 'STRONG BEER', 'Kingfisher Strong').first.closingBalance.beer650;
    expect(strong650Close, 34);
  });

  test('6. all spellings share one counter brand ID', () async {
    await shopDay();
    final all = await c.read(mastersRepositoryProvider).getMaterials();
    final ids = {for (final m in all.where((m) => ['K650', 'K500', 'K330', 'K1000', 'KM650'].contains(m.id))) m.counterBrandId};
    expect(ids.length, 1, reason: '$ids');
    expect(all.firstWhere((m) => m.id == 'T650').counterBrandId, isNot(ids.single));
  });

  test('7. renaming one drink\'s counter brand moves it to its own line; totals stay', () async {
    await shopDay();
    final before = await counter();
    final subBefore = before.categories.firstWhere((x) => x.name == 'STRONG BEER').subtotal;

    await c.read(mastersRepositoryProvider).updateMaterial(
        'K330', _mat('K330', 'KF SUPER STRONG 330 CAN', '330 ML (CAN)', 'Kingfisher Super Strong'));
    final r = await counter();
    final x = r.extraSizes;
    final sup = linesFor(r, 'STRONG BEER', 'Kingfisher Super Strong');
    expect(sup.length, 1);
    expect(_cols(sup.single.purchase, x)[5], 4);
    expect(_cols(sup.single.closingBalance, x)[5], 3);
    final kf = linesFor(r, 'STRONG BEER', 'Kingfisher Strong');
    expect(kf.fold<int>(0, (s, i) => s + i.purchase.beer330Can), 0, reason: '330 CAN left the Kingfisher Strong line');

    final subAfter = r.categories.firstWhere((x) => x.name == 'STRONG BEER').subtotal;
    expect(_cols(subAfter.closingBalance, x), _cols(subBefore.closingBalance, before.extraSizes));
    expect(_cols(subAfter.purchase, x), _cols(subBefore.purchase, before.extraSizes));
  });

  test('9. two 650 drinks of one counter brand in one TP add into one cell', () async {
    await shopDay();
    await c.read(mastersRepositoryProvider)
        .createMaterial(_mat('K650P', 'KF STRONG 650 PREMIUM', '650 ML', 'KINGFISHER STRONG'));
    await buy({'K650P': 4}, 'TP-D');
    await buy({'K650P': 1, 'K650': 1}, 'TP-E');
    final r = await counter();
    final kf = linesFor(r, 'STRONG BEER', 'Kingfisher Strong');
    expect(kf.map((i) => i.tpNo).toList(), ['TP-A', 'TP-B', 'TP-D', 'TP-E']);
    expect(kf.last.purchase.beer650, 2, reason: 'TP-E: one of each 650 drink');
    expect(kf.first.closingBalance.beer650, 34 + 4 + 2);
    final b = await brandwise();
    final rows = b.categories.firstWhere((x) => x.name == 'STRONG BEER').items;
    expect(rows.where((i) => i.brandName == 'KF STRONG 650 PREMIUM' && !i.isTpContinuation).length, 1,
        reason: 'Brandwise keeps the premium drink as its own row');
  });

  test('8. the Excel file shows exactly what the screen shows', () async {
    await shopDay();
    final r = await counter();
    final xml = CounterBrandwiseExcelExporter().buildWorkbook(r);
    final x = r.extraSizes;
    final width = 7 + x.length;

    // Each <Row> → its cell texts, in column order.
    final rows = [
      for (final m in RegExp(r'<Row[^>]*>(.*?)</Row>', dotAll: true).allMatches(xml))
        [for (final d in RegExp(r'<Data[^>]*>(.*?)</Data>', dotAll: true).allMatches(m.group(1)!)) d.group(1)!],
    ];
    String n(int v) => v == 0 ? '' : '$v';
    List<String> expected(CounterBrandwiseReportItemDto i) => [
          i.isTpContinuation ? '' : i.manufacturerName,
          i.tpNo ?? '',
          for (var k = 0; k < width; k++) n(i.openingBalance.at(k, x)),
          for (var k = 0; k < width; k++) n(i.purchase.at(k, x)),
          i.isTpContinuation ? '' : i.manufacturerName,
          for (var k = 0; k < width; k++) n(i.sale.at(k, x)),
          for (var k = 0; k < width; k++) n(i.closingBalance.at(k, x)),
        ];

    var checked = 0;
    for (final cat in r.categories) {
      for (final item in cat.items) {
        final want = expected(item).map((s) => s.replaceAll('&', '&amp;')).toList();
        expect(rows.where((row) => _listEq(row, want)).length, greaterThanOrEqualTo(1),
            reason: 'Excel row missing for ${cat.name} / ${item.manufacturerName} ${item.tpNo}');
        checked++;
      }
    }
    expect(checked, greaterThanOrEqualTo(4));
    expect(xml, contains('>1000ml<'), reason: 'extra size column header');
  });
}

bool _listEq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
