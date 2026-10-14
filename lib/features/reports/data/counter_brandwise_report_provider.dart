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
import 'counter_brandwise_excel_exporter.dart';
import 'models/brandwise_report_dto.dart';
import 'models/counter_brandwise_report_dto.dart';

// ---------------------------------------------------------------------------
//  Providers
// ---------------------------------------------------------------------------

final counterBrandwiseReportDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final counterBrandwiseExcelExporterProvider = Provider<CounterBrandwiseExcelExporter>((ref) {
  return CounterBrandwiseExcelExporter();
});

/// Re-fetches automatically whenever the date changes.
/// Offline-first: builds report from local Drift tables first, falls
/// back to the remote API only if local data is empty.
/// Aggregates quantities by **manufacturer** instead of individual brand.
final counterBrandwiseReportProvider = FutureProvider<CounterBrandwiseReportDto>((ref) async {
  final date = ref.watch(counterBrandwiseReportDateProvider);
  final db = ref.watch(appDatabaseProvider);

  // 1. Try to build from local data first.
  final local = await _buildLocalCounterBrandwiseReport(db, date);
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

/// Maps a material's `category` field (case-insensitive) to the
/// display name used in the report.
String? _mapCategory(String category) {
  final lower = category.toLowerCase().trim();
  if (lower.contains('fermented') || lower.contains('strong beer')) {
    return 'FERMENTED BEER';
  }
  if (lower.contains('mild') || lower.contains('mild beer')) {
    return 'MILD BEER';
  }
  if (lower.contains('wine') || lower.contains('whisky') || lower.contains('whiskey') ||
      lower.contains('rum') || lower.contains('vodka') || lower.contains('brandy') ||
      lower.contains('gin')) {
    return 'WINE';
  }
  // Catch-all for generic "beer" that isn't fermented/strong
  if (lower.contains('beer')) {
    return 'MILD BEER';
  }
  return null; // skip materials that don't fit the register (e.g. soft drinks)
}

/// Normalises packing strings into a column index.
int _packingIndex(String? packing) {
  if (packing == null || packing.trim().isEmpty) return -1;
  final normalized = packing.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final isCan = normalized.contains('can');
  final numMatch = RegExp(r'(\d+)').firstMatch(normalized);
  if (numMatch == null) return -1;
  final size = int.tryParse(numMatch.group(1)!) ?? 0;

  return switch (size) {
    750 => 0,   // wine750
    375 => 1,   // wine375
    180 => 2,   // wine180
    650 => 3,   // beer650
    500 => 4,   // beer500Can
    330 => isCan ? 5 : 6, // beer330Can or beer330Bottle
    _ => -1,
  };
}

/// Returns `null` if there's no local data at all (triggers API fallback).
Future<CounterBrandwiseReportDto?> _buildLocalCounterBrandwiseReport(AppDatabase db, DateTime date) async {
  final start = DateTime(date.year, date.month, date.day);
  final endExclusive = start.add(const Duration(days: 1));

  // Load active materials (for category / packing / manufacturer info)
  final rawMaterials = await db.select(db.cachedMaterials).get();
  final materials = rawMaterials.where((m) => m.isActive).toList();
  if (materials.isEmpty) return null;

  // Load sales for this day
  final saleBills = await (db.select(db.cachedSalesBills)
        ..where((t) => t.billDate.isBiggerOrEqualValue(start) & t.billDate.isSmallerThanValue(endExclusive)))
      .get();
  final saleBillIds = saleBills.map((b) => b.id).toList();

  List<CachedSaleLineItem> saleLines = [];
  if (saleBillIds.isNotEmpty) {
    saleLines = await (db.select(db.cachedSaleLineItems)
          ..where((t) => t.salesBillId.isIn(saleBillIds)))
        .get();
  }

  // Load purchases for this day
  final purchaseBills = await (db.select(db.cachedPurchaseBills)
        ..where((t) => t.billDate.isBiggerOrEqualValue(start) & t.billDate.isSmallerThanValue(endExclusive)))
      .get();
  final purchaseBillIds = purchaseBills.map((b) => b.id).toList();

  List<CachedPurchaseLineItem> purchaseLines = [];
  if (purchaseBillIds.isNotEmpty) {
    purchaseLines = await (db.select(db.cachedPurchaseLineItems)
          ..where((t) => t.purchaseBillId.isIn(purchaseBillIds)))
        .get();
  }

  // Load current inventory stock
  final inventoryStocks = await db.select(db.cachedInventoryStocks).get();
  final stockByMaterialId = {for (final s in inventoryStocks) s.materialId: s.qtyOnHand};

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

  // Build rows grouped by category, aggregated by manufacturer
  // Key: category display name → manufacturer name → aggregated quantities
  final categoryItems = <String, Map<String, _ManufacturerAgg>>{};

  for (final mat in materials) {
    final catName = _mapCategory(mat.category);
    if (catName == null) continue;

    final colIdx = _packingIndex(mat.packing);
    if (colIdx < 0) continue;

    final closing = stockByMaterialId[mat.id] ?? 0;
    final saleQty = saleQtyByMaterial[mat.id] ?? 0;
    final purchaseQty = purchaseQtyByMaterial[mat.id] ?? 0;
    final opening = closing + saleQty - purchaseQty;

    if (opening == 0 && saleQty == 0 && purchaseQty == 0 && closing == 0) continue;

    // Use manufacturer instead of individual brand name
    final trimmedMfr = mat.manufacturer.trim();
    final manufacturerName = trimmedMfr.isNotEmpty ? trimmedMfr : mat.name;

    final manufacturers = categoryItems.putIfAbsent(catName, () => {});
    final agg = manufacturers.putIfAbsent(manufacturerName, _ManufacturerAgg.new);
    agg.opening[colIdx] += opening;
    agg.purchase[colIdx] += purchaseQty;
    agg.sale[colIdx] += saleQty;
    agg.closing[colIdx] += closing;
  }

  if (categoryItems.isEmpty) return null;

  // Build DTOs in the fixed display order
  const categoryOrder = ['FERMENTED BEER', 'MILD BEER', 'WINE'];
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
    final items = sortedNames.map((name) {
      final agg = manufacturers[name]!;
      return CounterBrandwiseReportItemDto(
        manufacturerName: name,
        openingBalance: _listToSizeQty(agg.opening),
        purchase: _listToSizeQty(agg.purchase),
        sale: _listToSizeQty(agg.sale),
        closingBalance: _listToSizeQty(agg.closing),
      );
    }).toList();

    categories.add(CounterBrandwiseCategoryDto(
      name: catName,
      items: items,
      subtotal: CounterBrandwiseCategorySubtotal.compute(items),
    ));
  }

  return CounterBrandwiseReportDto(
    reportDate: date,
    licenseHeader: 'COUNTER BRANDWISE STOCK REPORT',
    categories: categories,
  );
}

BrandwiseSizeQty _listToSizeQty(List<int> vals) => BrandwiseSizeQty(
      wine750: vals[0],
      wine375: vals[1],
      wine180: vals[2],
      beer650: vals[3],
      beer500Can: vals[4],
      beer330Can: vals[5],
      beer330Bottle: vals[6],
    );

CounterBrandwiseReportDto _emptyReport(DateTime date) => CounterBrandwiseReportDto(
      reportDate: date,
      licenseHeader: 'COUNTER BRANDWISE STOCK REPORT',
      categories: const [
        CounterBrandwiseCategoryDto(
          name: 'FERMENTED BEER',
          items: [],
          subtotal: CounterBrandwiseCategorySubtotal(
            openingBalance: BrandwiseSizeQty.zero,
            purchase: BrandwiseSizeQty.zero,
            sale: BrandwiseSizeQty.zero,
            closingBalance: BrandwiseSizeQty.zero,
          ),
        ),
        CounterBrandwiseCategoryDto(
          name: 'MILD BEER',
          items: [],
          subtotal: CounterBrandwiseCategorySubtotal(
            openingBalance: BrandwiseSizeQty.zero,
            purchase: BrandwiseSizeQty.zero,
            sale: BrandwiseSizeQty.zero,
            closingBalance: BrandwiseSizeQty.zero,
          ),
        ),
        CounterBrandwiseCategoryDto(
          name: 'WINE',
          items: [],
          subtotal: CounterBrandwiseCategorySubtotal(
            openingBalance: BrandwiseSizeQty.zero,
            purchase: BrandwiseSizeQty.zero,
            sale: BrandwiseSizeQty.zero,
            closingBalance: BrandwiseSizeQty.zero,
          ),
        ),
      ],
    );

class _ManufacturerAgg {
  final opening = List<int>.filled(7, 0);
  final purchase = List<int>.filled(7, 0);
  final sale = List<int>.filled(7, 0);
  final closing = List<int>.filled(7, 0);
}
