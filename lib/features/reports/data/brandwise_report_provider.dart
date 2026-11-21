import 'dart:convert';
import '../../../core/clock.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/local/app_database.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/http_client_provider.dart';
import '../../masters/data/masters_providers.dart';
import 'brandwise_excel_exporter.dart';
import 'brandwise_sections.dart';
import 'models/brandwise_report_dto.dart';
import 'stock_as_of.dart';
import 'stock_movements.dart';

// ---------------------------------------------------------------------------
//  Providers
// ---------------------------------------------------------------------------

enum BrandwiseViewMode {
  brandwise,
  counterBrandwise,
}

final brandwiseViewModeProvider = StateProvider<BrandwiseViewMode>((ref) {
  return BrandwiseViewMode.brandwise;
});

final brandwiseReportDateProvider = StateProvider<DateTime>((ref) {
  final now = AppClock.now();
  return DateTime(now.year, now.month, now.day);
});

/// Off (default): only brands with stock or movement on the day.
/// On: every active material in the register, even at zero.
/// Inactive materials (Material Master status) never show.
final brandwiseShowAllProvider = StateProvider<bool>((ref) => false);

final brandwiseExcelExporterProvider = Provider<BrandwiseExcelExporter>((ref) {
  return BrandwiseExcelExporter();
});

/// Re-fetches automatically whenever the date changes.
/// Offline-first: builds report from local Drift tables first, falls
/// back to the remote API only if local data is empty.
final brandwiseReportProvider = FutureProvider<BrandwiseReportDto>((ref) async {
  final date = ref.watch(brandwiseReportDateProvider);
  final showAll = ref.watch(brandwiseShowAllProvider);
  final db = ref.watch(appDatabaseProvider);

  // 1. Try to build from local data first.
  final local = await _buildLocalBrandwiseReport(db, date, showAll: showAll);
  if (local != null) return local;

  // 2. In offline mode, return empty report. Otherwise try remote.
  if (AppConfig.offlineOnly) return _emptyReport(date);

  final client = ref.watch(httpClientProvider);
  try {
    return await _fetchRemoteBrandwiseReport(client, date);
  } on ApiException {
    return _emptyReport(date);
  }
});

// ---------------------------------------------------------------------------
//  Remote fetch
// ---------------------------------------------------------------------------

Future<BrandwiseReportDto> _fetchRemoteBrandwiseReport(http.Client client, DateTime date) async {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');

  try {
    final response = await client
        .get(
          ApiConfig.uri('/api/reports/brandwise-stock', {'date': '$y-$m-$d'}),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromStatusCode(response.statusCode);
    }

    return BrandwiseReportDto.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException('Could not load the brandwise report: $e');
  }
}

// ---------------------------------------------------------------------------
//  Local (offline) report builder
// ---------------------------------------------------------------------------


/// Returns `null` if there's no local data at all (triggers API fallback).
Future<BrandwiseReportDto?> _buildLocalBrandwiseReport(AppDatabase db, DateTime date, {bool showAll = false}) async {
  final start = DateTime(date.year, date.month, date.day);
  final endExclusive = start.add(const Duration(days: 1));

  // Load active materials (for category / packing info)
  final rawMaterials = await db.select(db.cachedMaterials).get();
  final materials = rawMaterials; // inactive ones are dropped below unless they moved
  if (materials.isEmpty) return null;

  // What moved this day. Returns count on the day they happen (a sale
  // return lowers that day's Sale; goods sent back lower that day's
  // Purchase, as a minus row under their TP), never on the original bill's
  // day, so a printed register never changes later.
  final moves = await stockMovements(db, start, endExclusive);

  // Stock at the end of the report day (not today's stock), so past
  // days report their own closing and opening balances.
  final stockByMaterialId = await closingStockAsOf(db, endExclusive);

  final saleQtyByMaterial = {for (final id in moves.materialIds) id: moves.netSale(id)};
  final purchaseQtyByMaterial = {for (final id in moves.materialIds) id: moves.netPurchase(id)};
  final tpQtyByMaterial = moves.tpRows;
  final tpOrder = moves.tpOrder;

  // Build rows grouped by category
  // Key: category display name → list of items
  final categoryItems = <String, Map<String, _BrandAgg>>{};

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

    final brands = categoryItems.putIfAbsent(catName, () => {});
    final agg = brands.putIfAbsent(mat.name, () => _BrandAgg(width));
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
  final categories = <BrandwiseCategoryDto>[];

  for (final catName in categoryOrder) {
    final brands = categoryItems[catName];
    if (brands == null || brands.isEmpty) {
      categories.add(BrandwiseCategoryDto(
        name: catName,
        items: const [],
        subtotal: const BrandwiseCategorySubtotal(
          openingBalance: BrandwiseSizeQty.zero,
          purchase: BrandwiseSizeQty.zero,
          sale: BrandwiseSizeQty.zero,
          closingBalance: BrandwiseSizeQty.zero,
        ),
      ));
      continue;
    }

    final sortedNames = brands.keys.toList()..sort();
    // One row per TP: the first carries opening/sale/closing, the
    // following rows only that TP's purchase (subtotals stay the same).
    final items = <BrandwiseReportItemDto>[];
    for (final name in sortedNames) {
      final agg = brands[name]!;
      final split = agg.tps.rows(tpOrder);
      for (var k = 0; k < split.length; k++) {
        final first = k == 0;
        items.add(BrandwiseReportItemDto(
          brandName: name,
          tpNo: split[k].tpNo,
          isTpContinuation: !first,
          openingBalance: first ? _listToSizeQty(agg.opening, extraSizes) : BrandwiseSizeQty.zero,
          purchase: _listToSizeQty(split[k].qty, extraSizes),
          sale: first ? _listToSizeQty(agg.sale, extraSizes) : BrandwiseSizeQty.zero,
          closingBalance: first ? _listToSizeQty(agg.closing, extraSizes) : BrandwiseSizeQty.zero,
        ));
      }
    }

    categories.add(BrandwiseCategoryDto(
      name: catName,
      items: items,
      subtotal: BrandwiseCategorySubtotal.compute(items),
    ));
  }

  return BrandwiseReportDto(
    extraSizes: extraSizes,
    reportDate: date,
    licenseHeader: 'BEER A : WINE BR. II BRANDWISE STOCK REPORT',
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

BrandwiseReportDto _emptyReport(DateTime date) => BrandwiseReportDto(
      reportDate: date,
      licenseHeader: 'BEER A : WINE BR. II BRANDWISE STOCK REPORT',
      categories: [
        for (final name in brandwiseSectionOrder)
          BrandwiseCategoryDto(
            name: name,
            items: const [],
            subtotal: const BrandwiseCategorySubtotal(
              openingBalance: BrandwiseSizeQty.zero,
              purchase: BrandwiseSizeQty.zero,
              sale: BrandwiseSizeQty.zero,
              closingBalance: BrandwiseSizeQty.zero,
            ),
          ),
      ],
    );

class _BrandAgg {
  _BrandAgg(int width)
      : opening = List<int>.filled(width, 0),
        sale = List<int>.filled(width, 0),
        closing = List<int>.filled(width, 0),
        tps = TpPurchaseSplit(width);

  final List<int> opening;
  final List<int> sale;
  final List<int> closing;
  final TpPurchaseSplit tps;
}
