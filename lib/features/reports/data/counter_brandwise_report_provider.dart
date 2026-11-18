import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/local/app_database.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/http_client_provider.dart';
import '../../masters/data/masters_providers.dart';
import 'brandwise_report_provider.dart';
import 'counter_brandwise_excel_exporter.dart';
import 'brandwise_sections.dart';
import 'models/brandwise_report_dto.dart';
import 'models/counter_brandwise_report_dto.dart';
import 'stock_as_of.dart';

// ---------------------------------------------------------------------------
//  Providers
// ---------------------------------------------------------------------------

/// Date provider for Counter Brandwise — alias to [brandwiseReportDateProvider] so date selection is always in sync.
final counterBrandwiseReportDateProvider = brandwiseReportDateProvider;

final counterBrandwiseExcelExporterProvider = Provider<CounterBrandwiseExcelExporter>((ref) {
  return CounterBrandwiseExcelExporter();
});

/// Re-fetches automatically whenever the date changes.
/// Offline-first: builds report from local Drift tables first, falls
/// back to the remote API only if local data is empty.
/// Aggregates quantities by **counter brand** (Material Master → Counter
/// Brand Name): every SCM row of "Kingfisher Strong" adds up to one line.
final counterBrandwiseReportProvider = FutureProvider<CounterBrandwiseReportDto>((ref) async {
  final date = ref.watch(counterBrandwiseReportDateProvider);
  final showAll = ref.watch(brandwiseShowAllProvider);
  final db = ref.watch(appDatabaseProvider);

  // 1. Try to build from local data first.
  final local = await _buildLocalCounterBrandwiseReport(db, date, showAll: showAll);
  if (local != null) return local;

  // 2. In offline mode, return empty report. Otherwise try remote.
  if (AppConfig.offlineOnly) return _emptyReport(date);

  final client = ref.watch(httpClientProvider);
  try {
    return await _fetchRemoteCounterBrandwiseReport(client, date);
  } on ApiException {
    return _emptyReport(date);
  }
});

// ---------------------------------------------------------------------------
//  Remote fetch
// ---------------------------------------------------------------------------

Future<CounterBrandwiseReportDto> _fetchRemoteCounterBrandwiseReport(http.Client client, DateTime date) async {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');

  try {
    final response = await client
        .get(
          ApiConfig.uri('/api/reports/counter-brandwise-stock', {'date': '$y-$m-$d'}),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromStatusCode(response.statusCode);
    }

    return CounterBrandwiseReportDto.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException('Could not load the counter brandwise report: $e');
  }
}

// ---------------------------------------------------------------------------
//  Local (offline) report builder
// ---------------------------------------------------------------------------


/// Returns `null` if there's no local data at all (triggers API fallback).
Future<CounterBrandwiseReportDto?> _buildLocalCounterBrandwiseReport(AppDatabase db, DateTime date, {bool showAll = false}) async {
  final start = DateTime(date.year, date.month, date.day);
  final endExclusive = start.add(const Duration(days: 1));

  // Load active materials (for category / packing / manufacturer info)
  final rawMaterials = await db.select(db.cachedMaterials).get();
  final materials = rawMaterials; // inactive ones are dropped below unless they moved
  if (materials.isEmpty) return null;

  // Load sales for this day
  // Fully returned bills are kept for audit but never counted.
  final saleLines = await (db.select(db.cachedSaleLineItems)
        ..where((t) => db.lineOfActiveBillBetween(t, start, endExclusive)))
      .get();

  // Load purchases for this day
  final purchaseBills = await (db.select(db.cachedPurchaseBills)
        ..where((t) =>
            db.isActivePurchaseBill(t) &
            t.billDate.isBiggerOrEqualValue(start) &
            t.billDate.isSmallerThanValue(endExclusive)))
      .get();
  final purchaseBillIds = purchaseBills.map((b) => b.id).toList();

  List<CachedPurchaseLineItem> purchaseLines = [];
  if (purchaseBillIds.isNotEmpty) {
    purchaseLines = await (db.select(db.cachedPurchaseLineItems)
          ..where((t) => t.purchaseBillId.isIn(purchaseBillIds)))
        .get();
  }

  // Stock at the end of the report day (not today's stock), so past
  // days report their own closing and opening balances.
  final stockByMaterialId = await closingStockAsOf(db, endExclusive);

  // Aggregate sale qty per materialId
  final saleQtyByMaterial = <String, int>{};
  for (final line in saleLines) {
    final mid = line.materialId ?? '';
    if (mid.isEmpty) continue;
    saleQtyByMaterial[mid] = (saleQtyByMaterial[mid] ?? 0) + line.quantity;
  }

  // Aggregate purchase qty per materialId
  final purchaseQtyByMaterial = <String, int>{};
  for (final line in purchaseLines) {
    purchaseQtyByMaterial[line.materialId] =
        (purchaseQtyByMaterial[line.materialId] ?? 0) + line.qty;
  }

  // TP numbers of the day's purchases, per materialId, in bill-time order
  // (ties broken by TP No so the register is stable).
  final billOrder = [...purchaseBills]
    ..sort((a, b) {
      final byTime = a.billDate.compareTo(b.billDate);
      return byTime != 0 ? byTime : (a.tpNo ?? '').compareTo(b.tpNo ?? '');
    });
  final tpQtyByMaterial = <String, List<(String?, int)>>{};
  for (final bill in billOrder) {
    for (final line in purchaseLines.where((l) => l.purchaseBillId == bill.id)) {
      tpQtyByMaterial.putIfAbsent(line.materialId, () => []).add((bill.tpNo, line.qty));
    }
  }

  // Build rows grouped by category, aggregated by manufacturer
  // Key: category display name → manufacturer name → aggregated quantities
  final categoryItems = <String, Map<String, _ManufacturerAgg>>{};

  // Whether a material shows on this day's register: it moved, or Show
  // all is on and it's active.
  bool shows(CachedMaterial mat) {
    final closing = stockByMaterialId[mat.id] ?? 0;
    final saleQty = saleQtyByMaterial[mat.id] ?? 0;
    final purchaseQty = purchaseQtyByMaterial[mat.id] ?? 0;
    final moved = closing != 0 || saleQty != 0 || purchaseQty != 0;
    return moved || (showAll && mat.isActive);
  }

  // Sizes with no register column (1000 ML, 2000 ML…) get their own
  // columns after the standard 7 — only the ones this report uses.
  final extraSizes = {
    for (final mat in materials)
      if (brandwiseSection(mat.category, mat.liquorType) != null &&
          registerColumn(mat.packing) < 0 &&
          mat.packing.trim().isNotEmpty &&
          shows(mat))
        extraSizeLabel(mat.packing),
  }.toList()
    ..sort(compareSizeLabels);
  final width = 7 + extraSizes.length;

  for (final mat in materials) {
    final catName = brandwiseSection(mat.category, mat.liquorType);
    if (catName == null) continue;

    final standardCol = registerColumn(mat.packing);
    final colIdx = standardCol >= 0
        ? standardCol
        : mat.packing.trim().isEmpty
            ? -1
            : 7 + extraSizes.indexOf(extraSizeLabel(mat.packing));
    if (colIdx < 0) continue;

    final closing = stockByMaterialId[mat.id] ?? 0;
    final saleQty = saleQtyByMaterial[mat.id] ?? 0;
    final purchaseQty = purchaseQtyByMaterial[mat.id] ?? 0;
    final opening = closing + saleQty - purchaseQty;

    final moved = opening != 0 || saleQty != 0 || purchaseQty != 0 || closing != 0;
    // Inactive materials are hidden unless they moved that day, so the
    // register always matches the bills. Show all adds idle active ones.
    if (!moved && (!showAll || !mat.isActive)) continue;

    // One line per counter brand (blank → the display name).
    final counterName = mat.counterBrandName.trim();
    final manufacturerName = counterName.isNotEmpty ? counterName : mat.name.trim();

    // Case / spacing variants of one counter brand are one line, shown
    // with the first spelling met.
    final manufacturers = categoryItems.putIfAbsent(catName, () => {});
    final key = manufacturers.keys.firstWhere(
      (k) => AppDatabase.normalizeCounterBrand(k) == AppDatabase.normalizeCounterBrand(manufacturerName),
      orElse: () => manufacturerName,
    );
    final agg = manufacturers.putIfAbsent(key, () => _ManufacturerAgg(width));
    agg.opening[colIdx] += opening;
    agg.sale[colIdx] += saleQty;
    agg.closing[colIdx] += closing;
    for (final (tp, qty) in tpQtyByMaterial[mat.id] ?? const <(String?, int)>[]) {
      agg.tps.add(tp, colIdx, qty);
    }
  }

  if (categoryItems.isEmpty) return null;

  // Build DTOs in the fixed display order
  const categoryOrder = brandwiseSectionOrder;
  final categories = <CounterBrandwiseCategoryDto>[];

  for (final catName in categoryOrder) {
    final manufacturers = categoryItems[catName];
    if (manufacturers == null || manufacturers.isEmpty) {
      categories.add(CounterBrandwiseCategoryDto(
        name: catName,
        items: const [],
        subtotal: const CounterBrandwiseCategorySubtotal(
          openingBalance: BrandwiseSizeQty.zero,
          purchase: BrandwiseSizeQty.zero,
          sale: BrandwiseSizeQty.zero,
          closingBalance: BrandwiseSizeQty.zero,
        ),
      ));
      continue;
    }

    final sortedNames = manufacturers.keys.toList()..sort();
    // One row per TP: the first carries opening/sale/closing, the
    // following rows only that TP's purchase (subtotals stay the same).
    final items = <CounterBrandwiseReportItemDto>[];
    for (final name in sortedNames) {
      final agg = manufacturers[name]!;
      final split = agg.tps.rows();
      for (var k = 0; k < split.length; k++) {
        final first = k == 0;
        items.add(CounterBrandwiseReportItemDto(
          manufacturerName: name,
          tpNo: split[k].tpNo,
          isTpContinuation: !first,
          openingBalance: first ? _listToSizeQty(agg.opening, extraSizes) : BrandwiseSizeQty.zero,
          purchase: _listToSizeQty(split[k].qty, extraSizes),
          sale: first ? _listToSizeQty(agg.sale, extraSizes) : BrandwiseSizeQty.zero,
          closingBalance: first ? _listToSizeQty(agg.closing, extraSizes) : BrandwiseSizeQty.zero,
        ));
      }
    }

    categories.add(CounterBrandwiseCategoryDto(
      name: catName,
      items: items,
      subtotal: CounterBrandwiseCategorySubtotal.compute(items),
    ));
  }

  return CounterBrandwiseReportDto(
    extraSizes: extraSizes,
    reportDate: date,
    licenseHeader: 'COUNTER BRANDWISE STOCK REPORT',
    categories: categories,
  );
}

BrandwiseSizeQty _listToSizeQty(List<int> vals, List<String> extraSizes) => BrandwiseSizeQty(
      wine750: vals[0],
      wine375: vals[1],
      wine180: vals[2],
      beer650: vals[3],
      beer500Can: vals[4],
      beer330Can: vals[5],
      beer330Bottle: vals[6],
      extra: {
        for (var i = 0; i < extraSizes.length; i++)
          if (vals[7 + i] != 0) extraSizes[i]: vals[7 + i],
      },
    );

CounterBrandwiseReportDto _emptyReport(DateTime date) => CounterBrandwiseReportDto(
      reportDate: date,
      licenseHeader: 'COUNTER BRANDWISE STOCK REPORT',
      categories: [
        for (final name in brandwiseSectionOrder)
          CounterBrandwiseCategoryDto(
            name: name,
            items: const [],
            subtotal: const CounterBrandwiseCategorySubtotal(
              openingBalance: BrandwiseSizeQty.zero,
              purchase: BrandwiseSizeQty.zero,
              sale: BrandwiseSizeQty.zero,
              closingBalance: BrandwiseSizeQty.zero,
            ),
          ),
      ],
    );

class _ManufacturerAgg {
  _ManufacturerAgg(int width)
      : opening = List<int>.filled(width, 0),
        sale = List<int>.filled(width, 0),
        closing = List<int>.filled(width, 0),
        tps = TpPurchaseSplit(width);

  final List<int> opening;
  final List<int> sale;
  final List<int> closing;
  final TpPurchaseSplit tps;
}
