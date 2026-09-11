import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/local/app_database.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/http_client_provider.dart';
import '../../masters/data/masters_providers.dart';
import 'brandwise_excel_exporter.dart';
import 'models/brandwise_report_dto.dart';

// ---------------------------------------------------------------------------
//  Providers
// ---------------------------------------------------------------------------

final brandwiseReportDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final brandwiseExcelExporterProvider = Provider<BrandwiseExcelExporter>((ref) {
  return BrandwiseExcelExporter();
});

/// Re-fetches automatically whenever the date changes.
/// Offline-first: builds report from local Drift tables first, falls
/// back to the remote API only if local data is empty.
final brandwiseReportProvider = FutureProvider<BrandwiseReportDto>((ref) async {
  final date = ref.watch(brandwiseReportDateProvider);
  final db = ref.watch(appDatabaseProvider);
  final client = ref.watch(httpClientProvider);

  // 1. Try to build from local data first.
  final local = await _buildLocalBrandwiseReport(db, date);
  if (local != null) return local;

  // 2. Fall back to remote API.
  try {
    return await _fetchRemoteBrandwiseReport(client, date);
  } on ApiException {
    // If API also fails, return an empty report so the UI doesn't crash.
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

/// Size-column names used in Material.packing → column index mapping.
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

/// Normalises packing strings like "750 ML", "750ml", "650ML",
/// "500ml CAN", "330 ML (CAN)", "330ml" etc. into a column index.
int _packingIndex(String? packing) {
  if (packing == null || packing.trim().isEmpty) return -1;
  // Normalise: lowercase, collapse spaces
  final normalized = packing.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final isCan = normalized.contains('can');
  // Extract leading digits
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
Future<BrandwiseReportDto?> _buildLocalBrandwiseReport(AppDatabase db, DateTime date) async {
  final start = DateTime(date.year, date.month, date.day);
  final endExclusive = start.add(const Duration(days: 1));

  // Load all materials (for category / packing info)
  final materials = await db.select(db.cachedMaterials).get();
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

  // Build rows grouped by category
  // Key: category display name → list of items
  final categoryItems = <String, Map<String, _BrandAgg>>{};

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

    final brands = categoryItems.putIfAbsent(catName, () => {});
    final agg = brands.putIfAbsent(mat.name, _BrandAgg.new);
    agg.opening[colIdx] += opening;
    agg.purchase[colIdx] += purchaseQty;
    agg.sale[colIdx] += saleQty;
    agg.closing[colIdx] += closing;
  }

  if (categoryItems.isEmpty) return null;

  // Build DTOs in the fixed display order
  const categoryOrder = ['FERMENTED BEER', 'MILD BEER', 'WINE'];
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
    final items = sortedNames.map((name) {
      final agg = brands[name]!;
      return BrandwiseReportItemDto(
        brandName: name,
        openingBalance: _listToSizeQty(agg.opening),
        purchase: _listToSizeQty(agg.purchase),
        sale: _listToSizeQty(agg.sale),
        closingBalance: _listToSizeQty(agg.closing),
      );
    }).toList();

    categories.add(BrandwiseCategoryDto(
      name: catName,
      items: items,
      subtotal: BrandwiseCategorySubtotal.compute(items),
    ));
  }

  return BrandwiseReportDto(
    reportDate: date,
    licenseHeader: 'BEER A : WINE BR. II BRANDWISE STOCK REPORT',
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

BrandwiseReportDto _emptyReport(DateTime date) => BrandwiseReportDto(
      reportDate: date,
      licenseHeader: 'BEER A : WINE BR. II BRANDWISE STOCK REPORT',
      categories: const [
        BrandwiseCategoryDto(
          name: 'FERMENTED BEER',
          items: [],
          subtotal: BrandwiseCategorySubtotal(
            openingBalance: BrandwiseSizeQty.zero,
            purchase: BrandwiseSizeQty.zero,
            sale: BrandwiseSizeQty.zero,
            closingBalance: BrandwiseSizeQty.zero,
          ),
        ),
        BrandwiseCategoryDto(
          name: 'MILD BEER',
          items: [],
          subtotal: BrandwiseCategorySubtotal(
            openingBalance: BrandwiseSizeQty.zero,
            purchase: BrandwiseSizeQty.zero,
            sale: BrandwiseSizeQty.zero,
            closingBalance: BrandwiseSizeQty.zero,
          ),
        ),
        BrandwiseCategoryDto(
          name: 'WINE',
          items: [],
          subtotal: BrandwiseCategorySubtotal(
            openingBalance: BrandwiseSizeQty.zero,
            purchase: BrandwiseSizeQty.zero,
            sale: BrandwiseSizeQty.zero,
            closingBalance: BrandwiseSizeQty.zero,
          ),
        ),
      ],
    );

class _BrandAgg {
  final opening = List<int>.filled(7, 0);
  final purchase = List<int>.filled(7, 0);
  final sale = List<int>.filled(7, 0);
  final closing = List<int>.filled(7, 0);
}
