// Four heavy shop days, replayed in seconds with a test clock.
//
// ~100 bills a day (400 in all) across 30 drinks in every register size,
// 4 TP purchases a day with VAT/TCS, rotating permits, walk-ins, partial
// and full sales returns (some of earlier days' bills), and partial
// purchase returns. A separate ledger in this test tracks what every
// report should say. At the end, for every day:
//
//  - Brandwise: each drink's opening / purchase / sale / closing, opening =
//    yesterday's closing, one row per TP;
//  - Counter Brandwise: each counter-brand line = the sum of its drinks;
//    section subtotals = Brandwise's;
//  - License Holder report: bottles and bills per permit;
//  - SCM upload export: bottles per SCM code;
//  - Excel builds for Brandwise and Counter Brandwise;
// and for the last day: Dashboard (today / 7 days), and Inventory stock.
//
// Returns change the register of the day the bill was made (the bill
// shrinks). The test checks reports against that rule, and also records
// which already-printed days changed later, for the client.
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pos_app/core/clock.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/features/dashboard/data/dashboard_api_repository.dart';
import 'package:pos_app/features/dashboard/data/local_dashboard_repository.dart';
import 'package:pos_app/features/dashboard/data/models/dashboard_summary_dto.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/masters/data/models/save_license_holder_request.dart';
import 'package:pos_app/features/masters/data/models/save_material_request.dart';
import 'package:pos_app/features/purchase/data/models/create_purchase_request.dart';
import 'package:pos_app/features/reports/data/brandwise_excel_exporter.dart';
import 'package:pos_app/features/reports/data/brandwise_report_provider.dart';
import 'package:pos_app/features/reports/data/counter_brandwise_excel_exporter.dart';
import 'package:pos_app/features/reports/data/counter_brandwise_report_provider.dart';
import 'package:pos_app/features/reports/data/license_holder_report.dart';
import 'package:pos_app/features/reports/data/models/brandwise_report_dto.dart';
import 'package:pos_app/features/reports/data/scm_upload_exporter.dart';
import 'package:pos_app/features/sales/data/models/create_sale_request.dart';

import 'support/test_env.dart';

const _days = 4;
const _billsPerDay = 100;
const _purchasesPerDay = 4;

/// (id, name, category, type, packing, counter brand, rate, opening stock)
const _catalog = <(String, String, String, String, String, String, double, int)>[
  ('S1', 'KF STRONG 650', 'Beer', 'Strong', '650 ML', 'Kingfisher Strong', 190, 120),
  ('S2', 'KF STRONG 500 CAN', 'Beer', 'Strong', '500 ML (CAN)', 'kingfisher strong', 160, 96),
  ('S3', 'KF STRONG 330 CAN', 'Beer', 'Strong', '330 ML (CAN)', 'Kingfisher Strong', 120, 48),
  ('S4', 'TUBORG STRONG 650', 'Beer', 'Strong', '650 ML', '', 200, 96),
  ('S5', 'TUBORG STRONG 500 CAN', 'Beer', 'Strong', '500 ML (CAN)', 'Tuborg Strong', 170, 48),
  ('S6', 'BUDWEISER MAGNUM 650', 'Beer', 'Strong', '650 ML', '', 240, 72),
  ('S7', 'HAYWARDS 5000 650', 'Beer', 'Strong', '650 ML', '', 150, 72),
  ('S8', 'GODFATHER 650', 'Beer', 'Strong', '650 ML', '', 170, 48),
  ('S9', 'BEER TOWER 1000', 'Beer', 'Strong', '1000 ML', 'Kingfisher Strong', 300, 24),
  ('M1', 'KF PREMIUM 650', 'Beer', 'Mild', '650 ML', 'Kingfisher Premium', 180, 96),
  ('M2', 'KF PREMIUM 330', 'Beer', 'Mild', '330 ML', 'Kingfisher Premium', 110, 48),
  ('M3', 'TUBORG GREEN 650', 'Beer', 'Mild', '650 ML', '', 185, 72),
  ('M4', 'CARLSBERG 650', 'Beer', 'Mild', '650 ML', '', 210, 48),
  ('M5', 'BUDWEISER 330 CAN', 'Beer', 'Mild', '330 ML (CAN)', '', 130, 48),
  ('M6', 'HEINEKEN 330', 'Beer', 'Mild', '330 ML', '', 150, 48),
  ('F1', 'BIRA WHITE 650', 'Beer', 'Fermented', '650 ML', '', 220, 48),
  ('F2', 'BIRA WHITE 330 CAN', 'Beer', 'Fermented', '330 ML (CAN)', 'Bira White', 140, 48),
  ('F3', 'HOEGAARDEN 330', 'Beer', 'Fermented', '330 ML', '', 260, 24),
  ('W1', 'SULA SHIRAZ 750', 'Wine', '', '750 ML', 'Sula', 850, 36),
  ('W2', 'SULA CHENIN 750', 'Wine', '', '750 ML', 'sula', 800, 36),
  ('W3', 'SULA RASA 375', 'Wine', '', '375 ML', 'Sula', 450, 24),
  ('W4', 'GROVER ZAMPA 750', 'Wine', '', '750 ML', '', 950, 24),
  ('W5', 'PORT WINE 180', 'Wine', '', '180 ML', '', 90, 60),
  ('W6', 'PORT WINE 1000', 'Wine', '', '1000 ML', 'Port Wine', 380, 24),
  ('W7', 'FRATELLI 750', 'Wine', '', '750 ML', '', 900, 24),
  ('W8', 'FOUR SEASONS 375', 'Wine', '', '375 ML', '', 420, 24),
  ('W9', 'BIG BANYAN 750', 'Wine', '', '750 ML', '', 700, 24),
  ('M7', 'KALYANI BLACK 650', 'Beer', 'Mild', '650 ML', '', 140, 72),
  ('S10', 'KNOCKOUT 650', 'Beer', 'Strong', '650 ML', '', 160, 72),
  ('S11', 'KNOCKOUT 500 CAN', 'Beer', 'Strong', '500 ML (CAN)', 'Knockout', 140, 48),
];

const _permits = ['LT-1', 'LT-2', 'LT-3', 'LT-4', 'LT-5', 'LT-6'];

/// What the test knows about one bill.
class _Bill {
  _Bill(this.id, this.day, this.permit, this.lines, this.rates);
  final String id;
  final int day;
  final String permit;
  final Map<int, (String, int)> lines; // line no → (material, qty left)
  final Map<String, double> rates;
  bool active = true;
  int get bottles => lines.values.fold(0, (s, l) => s + l.$2);
}

void main() {
  test('four heavy shop days: every report agrees with the bills', () async {
    final env = await TestEnv.create(fileBacked: false);
    final c = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(env.db)]);
    final rng = Random(20261120);
    final sw = Stopwatch()..start();
    final day0 = DateTime(2026, 11, 16); // Monday
    var clock = day0.add(const Duration(hours: 9));
    AppClock.override = () => clock;
    addTearDown(() => AppClock.override = null);

    // ── Masters and opening stock ──────────────────────────────────────
    final repo = c.read(mastersRepositoryProvider);
    final info = {for (final m in _catalog) m.$1: m};
    for (final m in _catalog) {
      await repo.createMaterial(SaveMaterialRequest(
          id: m.$1, scmCode: m.$1, barcode: 'BC${m.$1}', name: m.$2, manufacturer: 'MFG', category: m.$3,
          liquorType: m.$4, packing: m.$5, saleRate: m.$7, taxPercent: 0, counterBrandName: m.$6));
      await env.db.into(env.db.cachedInventoryStocks).insert(CachedInventoryStocksCompanion.insert(
          materialId: m.$1, barcode: 'BC${m.$1}', name: m.$2, category: m.$3, qtyOnHand: m.$8));
    }
    for (final p in _permits) {
      await repo.createLicenseHolder(SaveLicenseHolderRequest(permitNo: p, name: 'HOLDER $p'));
    }
    final ids = [for (final m in _catalog) m.$1];

    // ── The ledger ─────────────────────────────────────────────────────
    final opening = {for (final m in _catalog) m.$1: m.$8};
    final stock = Map.of(opening);
    // day → material → qty (purchases per bill so returns can shrink them)
    final purchaseLines = <String, (int, Map<String, int>, String)>{}; // bill id → (day, qty by material, TP)
    final bills = <_Bill>[];
    var permitTurn = 0, tpSeq = 0, salesReturns = 0, fullReturns = 0, purchaseReturns = 0, rejected = 0;
    final saleReturnAmountByDay = List<double>.filled(_days, 0);
    final printedSalesByDay = <int, Map<String, int>>{}; // what each day's register said that evening

    Future<BrandwiseReportDto> brandwiseFor(DateTime day) async {
      c.read(brandwiseReportDateProvider.notifier).state = day;
      c.invalidate(brandwiseReportProvider);
      return c.read(brandwiseReportProvider.future);
    }

    for (var d = 0; d < _days; d++) {
      final date = DateTime(day0.year, day0.month, day0.day + d);
      clock = date.add(const Duration(hours: 9));

      for (var i = 0; i < _billsPerDay; i++) {
        clock = clock.add(Duration(minutes: 5 + rng.nextInt(3)));

        // Deliveries spread through the day, for the items running lowest.
        if (i % (_billsPerDay ~/ _purchasesPerDay) == 0) {
          final low = (ids.toList()..sort((a, b) => stock[a]!.compareTo(stock[b]!))).take(6).toList();
          final qty = {for (final id in low) id: 24 + 12 * rng.nextInt(3)};
          final tp = 'TP-${++tpSeq}';
          final items = qty.entries.fold<double>(0, (s, e) => s + e.value * info[e.key]!.$7 * 0.7);
          final vat = (items * 0.1 * 100).roundToDouble() / 100;
          final tcs = ((items + vat) * 0.01 * 100).roundToDouble() / 100;
          final r = await env.purchases.createPurchase(CreatePurchaseRequest(
            supplierId: 'SUP-${1 + rng.nextInt(3)}', billNo: 'INV-$tpSeq', payMode: 'Credit', tpNo: tp,
            discount: 0, vat: vat, stamp: 0, tcs: tcs, loadingFreight: 0,
            netAmount: items + vat + tcs, totalAmount: items + vat + tcs,
            lineItems: [
              for (final e in qty.entries)
                CreatePurchaseLineItemRequest(materialId: e.key, batchNo: 'B', qty: e.value,
                    rate: info[e.key]!.$7 * 0.7, disPercent: 0, disAmount: 0, taxPercent: 0, taxAmount: 0,
                    amount: e.value * info[e.key]!.$7 * 0.7),
            ],
          ));
          purchaseLines[r.id] = (d, Map.of(qty), tp);
          qty.forEach((id, q) => stock[id] = stock[id]! + q);
        }

        // A basket of 1–4 drinks, at most 12 bottles (the legal limit).
        final basket = <String, int>{};
        final kinds = 1 + rng.nextInt(4);
        while (basket.length < kinds) {
          basket[ids[rng.nextInt(ids.length)]] = 1 + rng.nextInt(3);
        }
        final permit = _permits[permitTurn % _permits.length];
        final canSell = basket.entries.every((e) => stock[e.key]! >= e.value);
        final lines = [
          for (final e in basket.entries)
            CreateSaleLineItemRequest(
                materialId: e.key, barcodeNo: 'BC${e.key}', materialType: info[e.key]!.$3,
                materialName: info[e.key]!.$2, batchNo: null, packing: info[e.key]!.$5, quantity: e.value,
                qtyCase: 0, rate: info[e.key]!.$7, discountPercent: 0, discountAmount: 0, taxPercent: 0,
                taxAmount: 0, amount: e.value * info[e.key]!.$7),
        ];
        final total = lines.fold<double>(0, (s, l) => s + l.amount);
        try {
          final r = await env.sales.createSale(CreateSaleRequest(
              billNo: 'x', permitNo: permit, permitHolderName: 'HOLDER $permit',
              payMode: const ['Cash', 'Card', 'UPI'][i % 3], taxableValue: total, totalDiscount: 0, totalTax: 0,
              totalAmount: total, balanceDue: total, lineItems: lines));
          expect(canSell, isTrue, reason: 'bill should have been refused for stock');
          bills.add(_Bill(r.id, d, permit, {
            for (var k = 0; k < basket.length; k++) k + 1: (basket.keys.elementAt(k), basket.values.elementAt(k)),
          }, {for (final e in basket.keys) e: info[e]!.$7}));
          basket.forEach((id, q) => stock[id] = stock[id]! - q);
          permitTurn++;
        } on Exception {
          expect(canSell, isFalse, reason: 'bill refused although stock was there');
          rejected++;
        }

        // ~6%: a customer returns part of a bill, sometimes from an earlier day.
        if (bills.length > 5 && rng.nextInt(100) < 6) {
          final pool = bills.where((b) => b.active && b.bottles > 0).toList();
          final b = pool[rng.nextInt(pool.length)];
          final full = rng.nextInt(4) == 0;
          if (full) {
            await env.sales.returnSalesBill(b.id);
            b.lines.forEach((_, l) {
              stock[l.$1] = stock[l.$1]! + l.$2;
              saleReturnAmountByDay[d] += l.$2 * b.rates[l.$1]!;
            });
            b.active = false;
            fullReturns++;
          } else {
            final open = b.lines.entries.where((e) => e.value.$2 > 0).toList();
            final line = open[rng.nextInt(open.length)];
            final q = 1 + rng.nextInt(line.value.$2);
            await env.sales.returnSalesBill(b.id, lineQuantities: {line.key: q});
            final left = line.value.$2 - q;
            b.lines[line.key] = (line.value.$1, left);
            stock[line.value.$1] = stock[line.value.$1]! + q;
            saleReturnAmountByDay[d] += q * b.rates[line.value.$1]!;
            if (b.bottles == 0) b.active = false; // last bottle back: the bill is fully returned
            salesReturns++;
          }
        }
      }

      // One partial purchase return a day (a broken case sent back).
      final candidates = purchaseLines.entries.where((e) => e.value.$1 == d).toList();
      final pr = candidates[rng.nextInt(candidates.length)];
      final lineNo = 1 + rng.nextInt(pr.value.$2.length);
      final material = pr.value.$2.keys.elementAt(lineNo - 1);
      final back = min(6, stock[material]!);
      if (back > 0 && back < pr.value.$2[material]!) {
        clock = clock.add(const Duration(minutes: 3));
        await env.purchases.returnPurchaseBill(pr.key, lineQuantities: {lineNo: back});
        pr.value.$2[material] = pr.value.$2[material]! - back;
        stock[material] = stock[material]! - back;
        purchaseReturns++;
      }

      // The evening register, as it would be printed.
      final printed = await brandwiseFor(date);
      printedSalesByDay[d] = {
        for (final cat in printed.categories)
          for (final r in cat.items.where((r) => !r.isTpContinuation)) r.brandName: r.sale.total,
      };
    }

    // ── What every report should say ───────────────────────────────────
    int soldOn(int d, String id) => bills
        .where((b) => b.active && b.day == d)
        .fold(0, (s, b) => s + b.lines.values.where((l) => l.$1 == id).fold(0, (t, l) => t + l.$2));
    int boughtOn(int d, String id) =>
        purchaseLines.values.where((p) => p.$1 == d).fold(0, (s, p) => s + (p.$2[id] ?? 0));
    final closing = <int, Map<String, int>>{};
    var prev = Map.of(opening);
    for (var d = 0; d < _days; d++) {
      closing[d] = {for (final id in ids) id: prev[id]! + boughtOn(d, id) - soldOn(d, id)};
      prev = closing[d]!;
    }
    expect(closing[_days - 1], stock, reason: 'the ledger itself must balance');

    // Inventory = the ledger.
    for (final id in ids) {
      expect(await env.stockOf(id), stock[id], reason: 'inventory stock of $id');
    }

    final changedLater = <String>[];
    for (var d = 0; d < _days; d++) {
      final date = DateTime(day0.year, day0.month, day0.day + d);
      final r = await brandwiseFor(date);
      final x = r.extraSizes;
      final rows = {
        for (final cat in r.categories)
          for (final row in cat.items.where((i) => !i.isTpContinuation)) row.brandName: row,
      };
      final tpRows = [for (final cat in r.categories) ...cat.items];

      for (final m in _catalog) {
        final id = m.$1;
        final want = (
          open: d == 0 ? opening[id]! : closing[d - 1]![id]!,
          buy: boughtOn(d, id),
          sold: soldOn(d, id),
          close: closing[d]![id]!,
        );
        final row = rows[m.$2];
        if (row == null) {
          expect(want, (open: 0, buy: 0, sold: 0, close: 0), reason: 'day $d: ${m.$2} missing from Brandwise');
          continue;
        }
        final rowsOfBrand = <BrandwiseReportItemDto>[];
        var inBrand = false;
        for (final t in tpRows) {
          if (!t.isTpContinuation) inBrand = t.brandName == m.$2;
          if (inBrand) rowsOfBrand.add(t);
        }
        final got = (
          open: row.openingBalance.total,
          buy: rowsOfBrand.fold<int>(0, (s, t) => s + t.purchase.total),
          sold: row.sale.total,
          close: row.closingBalance.total,
        );
        expect(got, want, reason: 'day $d Brandwise ${m.$2}');
        // One row per TP the drink came in on that day.
        final tps = purchaseLines.values.where((p) => p.$1 == d && (p.$2[id] ?? 0) > 0).map((p) => p.$3).toSet();
        if (tps.isNotEmpty) expect(rowsOfBrand.map((t) => t.tpNo).toSet(), tps, reason: 'day $d ${m.$2} TP rows');

        if ((printedSalesByDay[d]![m.$2] ?? 0) != want.sold) changedLater.add('day ${d + 1} ${m.$2}');
      }

      // Counter Brandwise: every section subtotal equals Brandwise's.
      c.invalidate(counterBrandwiseReportProvider);
      final cr = await c.read(counterBrandwiseReportProvider.future);
      expect(cr.extraSizes, x, reason: 'day $d same extra size columns');
      for (final cat in r.categories) {
        final cc = cr.categories.firstWhere((k) => k.name == cat.name);
        for (var col = 0; col < 7 + x.length; col++) {
          for (final (label, a, b) in [
            ('opening', cat.subtotal.openingBalance, cc.subtotal.openingBalance),
            ('purchase', cat.subtotal.purchase, cc.subtotal.purchase),
            ('sale', cat.subtotal.sale, cc.subtotal.sale),
            ('closing', cat.subtotal.closingBalance, cc.subtotal.closingBalance),
          ]) {
            expect(b.at(col, x), a.at(col, x), reason: 'day $d ${cat.name} $label column $col');
          }
        }
      }
      // …and each counter line is the sum of its drinks.
      final kf = cr.categories
          .firstWhere((k) => k.name == 'STRONG BEER')
          .items
          .where((i) => i.manufacturerName.toLowerCase() == 'kingfisher strong');
      final kfIds = ['S1', 'S2', 'S3', 'S9'];
      expect(kf.fold<int>(0, (s, i) => s + i.sale.total), kfIds.fold<int>(0, (s, id) => s + soldOn(d, id)),
          reason: 'day $d Kingfisher Strong counter line');

      // Excel builds without trouble and carries the day's totals.
      expect(BrandwiseExcelExporter().buildWorkbook(r), contains('<Workbook'));
      expect(CounterBrandwiseExcelExporter().buildWorkbook(cr), contains('<Workbook'));

      // License Holder report for the day.
      final lh = await LicenseHolderReport.build(env.db, date, DateTime(date.year, date.month, date.day, 23, 59, 59, 999));
      for (final p in _permits) {
        final mine = bills.where((b) => b.active && b.day == d && b.permit == p);
        final row = lh.rows.where((row) => row.permitNo == p);
        final bottles = mine.fold<int>(0, (s, b) => s + b.bottles);
        if (bottles == 0 && mine.isEmpty) {
          expect(row, isEmpty, reason: 'day $d $p');
          continue;
        }
        expect(row.single.qtyBottles, bottles, reason: 'day $d License Holder $p bottles');
        expect(row.single.bills, mine.length, reason: 'day $d License Holder $p bills');
      }

      // SCM upload: bottles per SCM code for the day.
      final scm = await ScmUploadExporter.rows(env.db, date, date);
      for (final id in ids) {
        final row = scm.firstWhere((r) => r[1] == id);
        expect((row[5] as int?) ?? 0, soldOn(d, id), reason: 'day $d SCM $id');
      }
    }

    // ── Dashboard on the last evening ─────────────────────────────────
    final dash = LocalDashboardRepository(env.db, DashboardApiRepository(http.Client()), env.sales);
    double amountOn(int d) => bills
        .where((b) => b.active && b.day == d)
        .fold(0.0, (s, b) => s + b.lines.values.fold(0.0, (t, l) => t + l.$2 * b.rates[l.$1]!));
    final today = await dash.getPeriodSnapshot(DashboardPeriod.today, now: clock);
    expect(today.sales.current, closeTo(amountOn(_days - 1), 0.01), reason: 'Dashboard today');
    expect(today.sales.previous, closeTo(amountOn(_days - 2), 0.01), reason: 'Dashboard yesterday');
    expect(today.billCount.current, bills.where((b) => b.active && b.day == _days - 1).length);
    expect(today.salesReturns.current, closeTo(saleReturnAmountByDay[_days - 1], 0.01), reason: 'returns today');
    final week = await dash.getPeriodSnapshot(DashboardPeriod.week, now: clock);
    expect(week.sales.current, closeTo([for (var d = 0; d < _days; d++) amountOn(d)].reduce((a, b) => a + b), 0.01));

    // ignore: avoid_print
    print('Heavy days: ${bills.length} bills ($rejected refused for stock), $tpSeq purchases, '
        '$salesReturns partial + $fullReturns full sales returns, $purchaseReturns purchase returns, '
        'in ${sw.elapsedMilliseconds} ms.\n'
        'Registers that changed after their evening (returns of that day\'s bills later): '
        '${changedLater.isEmpty ? 'none' : changedLater.length} ${changedLater.take(6).toList()}');

    c.dispose();
    await env.dispose();
  }, timeout: const Timeout(Duration(minutes: 5)));
}
