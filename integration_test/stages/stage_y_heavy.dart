// Stage Y — four heavy shop days in the real app, then the screens checked.
//
// Run on its own (it moves the app's clock):
//   flutter test integration_test/app_flow_test.dart -d macos --dart-define=E2E_STAGES=Y
//
// Days 1–3 and most of day 4 go in through the app's own data layer (fast);
// on day 4 ten sales are scanned on the Sales screen and two purchases are
// keyed on the Purchase screen. A ledger here tracks what each screen must
// show; then the Brandwise and Counter Brandwise screens are read row by row
// for every day, and the Dashboard and Inventory screens for the last day.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/clock.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/core/format/money.dart';
import 'package:pos_app/features/dashboard/data/dashboard_providers.dart';
import 'package:pos_app/features/dashboard/data/models/dashboard_summary_dto.dart';
import 'package:pos_app/features/inventory/data/inventory_providers.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/masters/data/models/save_license_holder_request.dart';
import 'package:pos_app/features/masters/data/models/save_material_request.dart';
import 'package:pos_app/features/purchase/data/models/create_purchase_request.dart';
import 'package:pos_app/features/reports/data/brandwise_report_provider.dart';
import 'package:pos_app/features/sales/data/models/create_sale_request.dart';
import 'package:pos_app/features/sales/data/sales_providers.dart';
import 'package:pos_app/features/purchase/data/purchase_providers.dart';
import 'package:pos_app/shared/widgets/data/figure.dart';

import '../support/driver.dart';
import 'stage_b_purchase.dart' show addLine, setTp, saveBill;
import 'stage_c_sales.dart' show scan, saveSale, lastScan, lastMessage;

const _days = 4;
const _billsPerDay = 100;

/// (id, name, type, packing, counter brand, rate, opening stock); all Beer
/// except W* (Wine).
const _catalog = <(String, String, String, String, String, double, int)>[
  ('HS1', 'H KF STRONG 650', 'Strong', '650 ML', 'H Kingfisher Strong', 190, 150),
  ('HS2', 'H KF STRONG 500 CAN', 'Strong', '500 ML (CAN)', 'h kingfisher strong', 160, 120),
  ('HS3', 'H KF STRONG 330 CAN', 'Strong', '330 ML (CAN)', 'H Kingfisher Strong', 120, 72),
  ('HS4', 'H TUBORG STRONG 650', 'Strong', '650 ML', '', 200, 120),
  ('HS5', 'H BUDWEISER MAGNUM 650', 'Strong', '650 ML', '', 240, 96),
  ('HS6', 'H HAYWARDS 5000 650', 'Strong', '650 ML', '', 150, 96),
  ('HS7', 'H BEER TOWER 1000', 'Strong', '1000 ML', 'H Kingfisher Strong', 300, 36),
  ('HM1', 'H KF PREMIUM 650', 'Mild', '650 ML', '', 180, 120),
  ('HM2', 'H KF PREMIUM 330', 'Mild', '330 ML', '', 110, 72),
  ('HM3', 'H TUBORG GREEN 650', 'Mild', '650 ML', '', 185, 96),
  ('HM4', 'H BUDWEISER 330 CAN', 'Mild', '330 ML (CAN)', '', 130, 72),
  ('HF1', 'H BIRA WHITE 650', 'Fermented', '650 ML', '', 220, 72),
  ('HF2', 'H HOEGAARDEN 330', 'Fermented', '330 ML', '', 260, 48),
  ('HW1', 'H SULA SHIRAZ 750', '', '750 ML', 'H Sula', 850, 48),
  ('HW2', 'H SULA CHENIN 750', '', '750 ML', 'h sula', 800, 48),
  ('HW3', 'H SULA RASA 375', '', '375 ML', 'H Sula', 450, 36),
  ('HW4', 'H PORT WINE 180', '', '180 ML', '', 90, 96),
  ('HW5', 'H PORT WINE 1000', '', '1000 ML', '', 380, 36),
];

const _permits = ['HLT-1', 'HLT-2', 'HLT-3', 'HLT-4'];

class _Bill {
  _Bill(this.id, this.day, this.lines, this.rates);
  final String id;
  final int day;
  final Map<int, (String, int)> lines; // line no → (material, qty left)
  final Map<String, double> rates;
  bool active = true;
  int get bottles => lines.values.fold(0, (s, l) => s + l.$2);
  double get amount => lines.values.fold(0.0, (s, l) => s + l.$2 * rates[l.$1]!);
}

/// Everything the screens should show, worked out independently.
class _Ledger {
  final opening = {for (final m in _catalog) m.$1: m.$7};
  late final stock = Map.of(opening);
  final bills = <_Bill>[];
  final purchases = <String, (int, Map<String, int>, String)>{}; // id → (day, qty, TP)

  int soldOn(int d, String id) => bills
      .where((b) => b.active && b.day == d)
      .fold(0, (s, b) => s + b.lines.values.where((l) => l.$1 == id).fold(0, (t, l) => t + l.$2));
  int boughtOn(int d, String id) => purchases.values.where((p) => p.$1 == d).fold(0, (s, p) => s + (p.$2[id] ?? 0));
  Map<String, int> closingOn(int d) {
    var prev = Map.of(opening);
    for (var k = 0; k <= d; k++) {
      prev = {for (final m in _catalog) m.$1: prev[m.$1]! + boughtOn(k, m.$1) - soldOn(k, m.$1)};
    }
    return prev;
  }

  double salesOn(int d) => bills.where((b) => b.active && b.day == d).fold(0.0, (s, b) => s + b.amount);
}

Future<void> stageY(Driver d) async {
  final today = DateTime.now();
  final day0 = DateTime(today.year, today.month, today.day - (_days - 1));
  var clock = day0.add(const Duration(hours: 9));
  AppClock.override = () => clock;
  final ledger = _Ledger();
  final info = {for (final m in _catalog) m.$1: m};
  final ids = [for (final m in _catalog) m.$1];
  final rng = Random(20261121);
  DateTime dayDate(int k) => DateTime(day0.year, day0.month, day0.day + k);

  try {
    await d.step('y1', 'Four heavy days entered: 400 bills, purchases with TPs, returns', () async {
      await d.t.runAsync(() async {
        final repo = d.c.read(mastersRepositoryProvider);
        final suppliers = await repo.getSuppliers();
        final supplierId = suppliers.first.id;
        for (final m in _catalog) {
          await repo.createMaterial(SaveMaterialRequest(
              id: m.$1, scmCode: m.$1, barcode: m.$1, name: m.$2, manufacturer: 'UB Group',
              category: m.$3.isEmpty ? 'Wine' : 'Beer', liquorType: m.$3, packing: m.$4, saleRate: m.$6,
              taxPercent: 0, counterBrandName: m.$5, defaultSupplierId: supplierId));
          await d.db.into(d.db.cachedInventoryStocks).insert(CachedInventoryStocksCompanion.insert(
              materialId: m.$1, barcode: m.$1, name: m.$2, category: m.$3.isEmpty ? 'Wine' : 'Beer', qtyOnHand: m.$7));
        }
        for (final p in _permits) {
          await repo.createLicenseHolder(SaveLicenseHolderRequest(permitNo: p, name: 'HOLDER $p'));
        }
        await repo.onMaterialsChanged?.call();

        final sales = d.c.read(salesRepositoryProvider);
        final purchases = d.c.read(purchaseRepositoryProvider);
        var tpSeq = 0, turn = 0;
        for (var day = 0; day < _days; day++) {
          clock = dayDate(day).add(const Duration(hours: 9));
          // Day 4 leaves room for the sales made on screen afterwards.
          final count = day == _days - 1 ? _billsPerDay - 10 : _billsPerDay;
          for (var i = 0; i < count; i++) {
            clock = clock.add(Duration(minutes: 4 + rng.nextInt(3)));
            if (i % 25 == 0) {
              final low = (ids.toList()..sort((a, b) => ledger.stock[a]!.compareTo(ledger.stock[b]!))).take(5);
              final qty = {for (final id in low) id: 24 + 12 * rng.nextInt(2)};
              final tp = 'HTP-${++tpSeq}';
              final r = await purchases.createPurchase(CreatePurchaseRequest(
                supplierId: supplierId, billNo: 'HINV-$tpSeq', payMode: 'Credit', tpNo: tp,
                discount: 0, vat: 0, stamp: 0, tcs: 0, loadingFreight: 0, netAmount: 0, totalAmount: 0,
                lineItems: [
                  for (final e in qty.entries)
                    CreatePurchaseLineItemRequest(materialId: e.key, batchNo: 'B', qty: e.value, rate: 100,
                        disPercent: 0, disAmount: 0, taxPercent: 0, taxAmount: 0, amount: e.value * 100.0),
                ],
              ));
              ledger.purchases[r.id] = (day, Map.of(qty), tp);
              qty.forEach((id, q) => ledger.stock[id] = ledger.stock[id]! + q);
            }

            final basket = <String, int>{};
            final kinds = 1 + rng.nextInt(3);
            while (basket.length < kinds) {
              basket[ids[rng.nextInt(ids.length)]] = 1 + rng.nextInt(3);
            }
            if (!basket.entries.every((e) => ledger.stock[e.key]! >= e.value)) continue;
            final permit = _permits[turn++ % _permits.length];
            final lines = [
              for (final e in basket.entries)
                CreateSaleLineItemRequest(
                    materialId: e.key, barcodeNo: e.key, materialType: info[e.key]!.$3, materialName: info[e.key]!.$2,
                    batchNo: null, packing: info[e.key]!.$4, quantity: e.value, qtyCase: 0, rate: info[e.key]!.$6,
                    discountPercent: 0, discountAmount: 0, taxPercent: 0, taxAmount: 0,
                    amount: e.value * info[e.key]!.$6),
            ];
            final total = lines.fold<double>(0, (s, l) => s + l.amount);
            final r = await sales.createSale(CreateSaleRequest(
                billNo: 'x', permitNo: permit, permitHolderName: 'HOLDER $permit', payMode: 'Cash',
                taxableValue: total, totalDiscount: 0, totalTax: 0, totalAmount: total, balanceDue: total,
                lineItems: lines));
            ledger.bills.add(_Bill(r.id, day, {
              for (var k = 0; k < basket.length; k++) k + 1: (basket.keys.elementAt(k), basket.values.elementAt(k)),
            }, {for (final id in basket.keys) id: info[id]!.$6}));
            basket.forEach((id, q) => ledger.stock[id] = ledger.stock[id]! - q);

            // ~6% returns, some of earlier days' bills.
            if (ledger.bills.length > 5 && rng.nextInt(100) < 6) {
              final pool = ledger.bills.where((b) => b.active && b.bottles > 0).toList();
              final b = pool[rng.nextInt(pool.length)];
              if (rng.nextInt(4) == 0) {
                await sales.returnSalesBill(b.id);
                b.lines.forEach((_, l) => ledger.stock[l.$1] = ledger.stock[l.$1]! + l.$2);
                b.active = false;
              } else {
                final open = b.lines.entries.where((e) => e.value.$2 > 0).toList();
                final line = open[rng.nextInt(open.length)];
                final q = 1 + rng.nextInt(line.value.$2);
                await sales.returnSalesBill(b.id, lineQuantities: {line.key: q});
                b.lines[line.key] = (line.value.$1, line.value.$2 - q);
                ledger.stock[line.value.$1] = ledger.stock[line.value.$1]! + q;
                if (b.bottles == 0) b.active = false;
              }
            }
          }
        }
        await repo.onMaterialsChanged?.call();
      });
      return ledger.bills.length >= 350 ? null : 'Only ${ledger.bills.length} bills were made.';
    });

    await d.step('y2', 'Day 4 on screen: 10 sales scanned, 2 purchases keyed with TPs', () async {
      clock = clock.add(const Duration(minutes: 10));
      await d.go('/sales');
      const last = _days - 1;
      for (var i = 0; i < 10; i++) {
        final id = ids.where((x) => ledger.stock[x]! >= 2).elementAt(i % 8);
        await scan(d, id);
        final bill = await saveSale(d);
        if (bill == null) return 'Sale ${i + 1} ($id) was not saved. Scan: $lastScan; screen: "$lastMessage"';
        final lines = (await d.t.runAsync(() =>
            (d.db.select(d.db.cachedSaleLineItems)..where((t) => t.salesBillId.equals(bill.id))).get()))!;
        ledger.bills.add(_Bill(bill.id, last, {for (final l in lines) l.lineNumber: (l.materialId!, l.quantity)},
            {for (final l in lines) l.materialId!: l.rate}));
        for (final l in lines) {
          ledger.stock[l.materialId!] = ledger.stock[l.materialId!]! - l.quantity;
        }
      }
      for (final (tp, id, qty) in [('HTP-UI-1', 'HS1', 24), ('HTP-UI-2', 'HW1', 12)]) {
        await d.go('/purchase');
        await addLine(d, id, qty);
        await setTp(d, tp);
        final msg = await saveBill(d);
        final bill = (await d.t.runAsync(() =>
                (d.db.select(d.db.cachedPurchaseBills)..where((t) => t.tpNo.equals(tp))).getSingleOrNull()))
            ;
        if (bill == null) return 'Purchase $tp was not saved: "$msg"';
        ledger.purchases[bill.id] = (last, {id: qty}, tp);
        ledger.stock[id] = ledger.stock[id]! + qty;
      }
      return null;
    });

    for (var day = 0; day < _days; day++) {
      await d.step('y${3 + day}', 'Brandwise screen, day ${day + 1}: every drink matches the bills', () async {
        await _showReport(d, dayDate(day), counter: false);
        final closing = ledger.closingOn(day);
        final prevClosing = day == 0 ? ledger.opening : ledger.closingOn(day - 1);
        final problems = <String>[];
        for (final m in _catalog) {
          final want = (prevClosing[m.$1]!, ledger.boughtOn(day, m.$1), ledger.soldOn(day, m.$1), closing[m.$1]!);
          final got = _screenRow(d, m.$2);
          if (got == null) {
            if (want != (0, 0, 0, 0)) problems.add('${m.$2} not on screen');
            continue;
          }
          if (got != want) problems.add('${m.$2}: screen $got, bills $want');
        }
        return problems.isEmpty ? null : problems.take(4).join('; ');
      });
    }

    await d.step('y7', 'Counter Brandwise screen: Kingfisher Strong and Sula lines, every day', () async {
      final problems = <String>[];
      for (var day = 0; day < _days; day++) {
        await _showReport(d, dayDate(day), counter: true);
        for (final (line, members) in [
          ('H Kingfisher Strong', ['HS1', 'HS2', 'HS3', 'HS7']),
          ('H Sula', ['HW1', 'HW2', 'HW3']),
        ]) {
          final got = _screenRow(d, line);
          final sold = members.fold<int>(0, (s, id) => s + ledger.soldOn(day, id));
          final bought = members.fold<int>(0, (s, id) => s + ledger.boughtOn(day, id));
          final close = members.fold<int>(0, (s, id) => s + ledger.closingOn(day)[id]!);
          if (got == null || (got.$2, got.$3, got.$4) != (bought, sold, close)) {
            problems.add('day ${day + 1} $line: screen $got, bills (purchase $bought, sale $sold, closing $close)');
          }
        }
      }
      return problems.isEmpty ? null : problems.take(3).join('; ');
    });

    await d.step('y8', 'Dashboard screen: today\'s and 7-day sales equal the bills', () async {
      final problems = <String>[];
      for (final (period, amount) in [
        (DashboardPeriod.today, ledger.salesOn(_days - 1)),
        (DashboardPeriod.week, [for (var k = 0; k < _days; k++) ledger.salesOn(k)].reduce((a, b) => a + b)),
      ]) {
        d.c.read(dashboardPeriodProvider.notifier).state = period;
        d.c.invalidate(dashboardSnapshotProvider);
        await d.go('/dashboard');
        await d.wait(const Duration(milliseconds: 800));
        final want = Money.inr(amount, decimals: 0, symbol: false);
        final shown = find.byWidgetPredicate((w) => w is Figure && w.value == want).evaluate().isNotEmpty;
        if (!shown) {
          final figures = find.byType(Figure).evaluate().map((e) => (e.widget as Figure).value).take(4).toList();
          problems.add('${period.label}: expected $want, screen shows $figures');
        }
      }
      d.c.read(dashboardPeriodProvider.notifier).state = DashboardPeriod.week;
      return problems.isEmpty ? null : problems.join('; ');
    });

    await d.step('y9', 'Inventory screen: stock of every drink equals the bills', () async {
      await d.go('/inventory');
      final problems = <String>[];
      for (final m in _catalog) {
        d.c.read(inventorySearchFilterProvider.notifier).state = m.$2;
        await d.idle(300);
        final name = find.text(m.$2);
        if (name.evaluate().isEmpty) {
          problems.add('${m.$2} not listed');
          continue;
        }
        final row = find.ancestor(of: name.first, matching: find.byType(Row)).last;
        final texts = find.descendant(of: row, matching: find.byType(Text)).evaluate().map((e) => (e.widget as Text).data);
        if (!texts.contains('${ledger.stock[m.$1]}')) {
          problems.add('${m.$2}: expected ${ledger.stock[m.$1]}, row shows ${texts.toList()}');
        }
      }
      d.c.read(inventorySearchFilterProvider.notifier).state = '';
      return problems.isEmpty ? null : problems.take(3).join('; ');
    });
  } finally {
    AppClock.override = null;
  }
}

/// Opens Brandwise (or Counter Brandwise) for [day] and generates it.
Future<void> _showReport(Driver d, DateTime day, {required bool counter}) async {
  await d.go('/brandwise-report');
  await d.tapText(counter ? 'Counter Brandwise' : 'Brandwise');
  // Pick the day in the date picker, as a person does: open it, switch to
  // typing, enter the date, OK.
  final field = find.descendant(
      of: find.ancestor(of: find.text('REPORT DATE'), matching: find.byType(Column)).first,
      matching: find.byType(InkWell));
  await d.t.tap(field.first);
  await d.idle();
  await d.t.tap(find.byTooltip('Switch to input'));
  await d.idle();
  String two(int v) => v.toString().padLeft(2, '0');
  await d.t.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)).first,
      '${two(day.month)}/${two(day.day)}/${day.year}');
  await d.idle();
  await d.tapText('OK');
  await d.tapText('Generate');
  final picked = d.c.read(brandwiseReportDateProvider);
  if (DateTime(picked.year, picked.month, picked.day) != DateTime(day.year, day.month, day.day)) {
    throw StateError('report date is $picked, wanted $day');
  }
  await d.wait(const Duration(milliseconds: 900));
}

/// The (opening, purchase, sale, closing) totals the report table shows for
/// [brand], adding up its extra TP rows' purchases; null if not listed.
(int, int, int, int)? _screenRow(Driver d, String brand) {
  final rows = find.byWidgetPredicate((w) => w is Tooltip && w.message == brand).evaluate().toList();
  if (rows.isEmpty) return null;
  int sum(Iterable<String?> cells) => cells.fold(0, (s, c) => s + (int.tryParse(c ?? '') ?? 0));
  (int, int, int, int)? main;
  var extraPurchase = 0;
  for (final tip in rows) {
    final row = find.ancestor(of: find.byElementPredicate((e) => e == tip), matching: find.byType(Row)).first;
    final texts = find.descendant(of: row, matching: find.byType(Text)).evaluate().map((e) => (e.widget as Text).data).toList();
    // opening + purchase cells, the brand, sale + closing cells.
    if (texts.length.isEven || texts.length < 5) continue;
    final mid = (texts.length - 1) ~/ 2;
    final cols = mid ~/ 2;
    final open = sum(texts.sublist(0, cols)), buy = sum(texts.sublist(cols, mid));
    final sale = sum(texts.sublist(mid + 1, mid + 1 + cols)), close = sum(texts.sublist(mid + 1 + cols, mid + 1 + 2 * cols));
    if (texts[mid] == brand) {
      main = (open, buy, sale, close);
    } else {
      extraPurchase += buy;
    }
  }
  return main == null ? null : (main.$1, main.$2 + extraPurchase, main.$3, main.$4);
}
