// Dev-only: renders real Caskly screens at fixed Windows resolutions and
// saves PNGs, so UI work can be reviewed without clicking through the app.
//
//   flutter run -d macos -t tooling/ui_snapshot.dart \
//     --dart-define=SNAP_OUT=/tmp/caskly_snaps --dart-define=SNAP_ROUTES=/sales,/dashboard
//
// Uses an in-memory database seeded with demo data — your real data is
// never touched. Signs in as an owner and fills the sales cart.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/app/router.dart';
import 'package:pos_app/core/auth/app_user.dart';
import 'package:pos_app/core/auth/auth_controller.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/core/local/material_lookup_cache.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/core/theme/app_typography.dart';
import 'package:pos_app/core/theme/font_scale_provider.dart';
import 'package:pos_app/core/theme/theme_mode_provider.dart';
import 'package:pos_app/features/masters/data/masters_providers.dart';
import 'package:pos_app/features/purchase/domain/purchase_line_item.dart';
import 'package:pos_app/features/purchase/presentation/purchase_cart_controller.dart';
import 'package:pos_app/features/sales/presentation/cart_controller.dart';

const _outOverride = String.fromEnvironment('SNAP_OUT');
late final String _out;
const _routes = String.fromEnvironment('SNAP_ROUTES', defaultValue: '/sales');
// Logical sizes Windows reports: 1366x768 @125% ≈ 1093x614, 1920x1080 @150%
// = 1280x720, plus the unscaled 1366x768 and 1920x1080.
const _allSizes = [Size(1093, 614), Size(1280, 720), Size(1366, 768), Size(1920, 1080)];

/// --dart-define=SNAP_SCALE=2 renders at 2x (e.g. 3840x2160 for 1920x1080)
/// and, for speed, only at 1920x1080 — used for crisp promo-video close-ups.
const _scale = int.fromEnvironment('SNAP_SCALE', defaultValue: 1);
const _sizes = _scale > 1 ? [Size(1920, 1080)] : _allSizes;

final _boundaryKey = GlobalKey();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false; // prove bundled fonts load
  // The macOS app is sandboxed, so default to its own temp folder.
  _out = _outOverride.isNotEmpty ? _outOverride : '${(await getTemporaryDirectory()).path}/caskly_snaps';
  final db = AppDatabase(NativeDatabase.memory());
  // --dart-define=SNAP_SHOP=beer: a believable Maharashtra beer & wine shop
  // (promo/demo videos) instead of the generic demo catalog.
  if (const String.fromEnvironment('SNAP_SHOP') == 'beer') await _seedBeerShop(db);
  await db.ensureStarterData(includeDemoData: true);
  final cache = await MaterialLookupCache.load(db);

  const owner = AppUser(id: 'snap', username: 'owner', displayName: 'Store Owner', role: UserRole.owner);
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
    currentUserProvider.overrideWithValue(owner),
  ]);
  container.read(materialLookupCacheProvider.notifier).state = cache;
  // --dart-define=SNAP_FONT_SCALE=1.35 renders at a larger Text size setting
  // (overflow errors show up in the log).
  const fontScale = String.fromEnvironment('SNAP_FONT_SCALE');
  if (fontScale.isNotEmpty) container.read(appFontScaleProvider.notifier).setScale(double.parse(fontScale));

  final router = buildAppRouter(UserRole.owner);
  final sizeNotifier = ValueNotifier(_sizes.first);

  runApp(UncontrolledProviderScope(
    container: container,
    child: ValueListenableBuilder<Size>(
      valueListenable: sizeNotifier,
      builder: (context, size, _) => Consumer(builder: (context, ref, _) {
        final mode = ref.watch(appThemeModeProvider);
        AppTypography.currentBrightness = mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
        return Directionality(
          textDirection: TextDirection.ltr,
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: size.width,
            maxWidth: size.width,
            minHeight: size.height,
            maxHeight: size.height,
            child: RepaintBoundary(
              key: _boundaryKey,
              child: MediaQuery(
                // Same text scaling the real app applies (Settings → Text size).
                data: MediaQueryData(
                  size: size,
                  devicePixelRatio: 1,
                  textScaler: TextScaler.linear(container.read(appFontScaleProvider)),
                ),
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode: mode,
                  routerConfig: router,
                ),
              ),
            ),
          ),
        );
      }),
    ),
  ));

  await Directory(_out).create(recursive: true);
  await Future<void>.delayed(const Duration(seconds: 2)); // fonts + first data load

  if (_routes.contains('/sales')) {
    router.go('/sales');
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await _capture('sales_empty_light_1366x768');
  }

  // A realistic cart: five different bottles.
  final cart = container.read(cartControllerProvider.notifier);
  final mats = await (db.select(db.cachedMaterials)..limit(5)).get();
  for (var i = 0; i < mats.length; i++) {
    await cart.addByBarcode(mats[i].barcode, qty: 1 + i % 2);
  }

  // A realistic purchase: six lines.
  final purchase = container.read(purchaseCartControllerProvider.notifier);
  final pmats = await (db.select(db.cachedMaterials)..limit(6)).get();
  for (var i = 0; i < pmats.length; i++) {
    final m = pmats[i];
    purchase.addLine(PurchaseLineItem(
      index: i + 1,
      materialId: m.id,
      manufacturer: m.manufacturer,
      material: m.name,
      batch: 'B-${2600 + i}',
      packing: '12x${m.packing}',
      qty: 12 * (i + 1),
      rate: m.saleRate * 0.8,
      discountPercent: i.isEven ? 2 : 0,
      taxPercent: m.taxPercent,
    ));
  }

  for (final route in _routes.split(',')) {
    router.go(route);
    container.read(appThemeModeProvider.notifier).state = ThemeMode.light;
    await Future<void>.delayed(const Duration(milliseconds: 2500)); // let the screen load its data
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      container.read(appThemeModeProvider.notifier).state = mode;
      for (final size in _sizes) {
        sizeNotifier.value = size;
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        await _capture('${route.replaceAll('/', '')}_${mode.name}_${size.width.toInt()}x${size.height.toInt()}');
      }
    }
  }
  // ignore: avoid_print
  print('SNAPSHOTS_DONE $_out');
  exit(0);
}

Future<void> _capture(String name) async {
  // Hidden/occluded macOS windows stop producing frames; force one and
  // don't wait forever.
  // Hidden/occluded macOS windows get few or no frames, which also stalls
  // loading and animations; drive ~1.5 s of frames before capturing.
  for (var i = 0; i < 90; i++) {
    WidgetsBinding.instance.scheduleForcedFrame();
    await WidgetsBinding.instance.endOfFrame.timeout(const Duration(milliseconds: 60), onTimeout: () {});
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
  final boundary = _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: _scale.toDouble());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File('$_out/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('saved $name');
}

// Keep the import used even if GoRouter APIs change.
// ignore: unused_element
typedef _R = GoRouter;


// ── beer & wine shop for promo shots ─────────────────────────────────────

// name, manufacturer, category, size, MRP, on hand, daily pace
const _beerShop = <(String, String, String, String, double, int, int)>[
  ('Kingfisher Strong', 'United Breweries', 'Fermented Beer', '650 ML', 180, 240, 22),
  ('Kingfisher Strong', 'United Breweries', 'Fermented Beer', '500 ML CAN', 190, 96, 9),
  ('Tuborg Strong', 'Carlsberg India', 'Fermented Beer', '650 ML', 170, 132, 11),
  ('Budweiser Magnum', 'AB InBev', 'Fermented Beer', '650 ML', 210, 96, 7),
  ('Haywards 5000', 'SABMiller', 'Fermented Beer', '650 ML', 150, 144, 9),
  ('Carlsberg Elephant', 'Carlsberg India', 'Fermented Beer', '650 ML', 200, 60, 4),
  ('Kingfisher Premium', 'United Breweries', 'Mild Beer', '650 ML', 160, 120, 9),
  ('Kingfisher Premium', 'United Breweries', 'Mild Beer', '330 ML CAN', 110, 96, 7),
  ('Budweiser', 'AB InBev', 'Mild Beer', '650 ML', 200, 84, 6),
  ('Bira 91 White', 'B9 Beverages', 'Mild Beer', '330 ML CAN', 140, 7, 4),
  ('Heineken', 'United Breweries', 'Mild Beer', '650 ML', 220, 48, 3),
  ('Sula Shiraz', 'Sula Vineyards', 'Wine', '750 ML', 820, 12, 1),
  ('Sula Chenin Blanc', 'Sula Vineyards', 'Wine', '750 ML', 790, 9, 1),
  ('Big Banyan Merlot', 'Big Banyan', 'Wine', '750 ML', 900, 10, 1),
  ('Golconda Port Wine', 'Golconda', 'Wine', '180 ML', 90, 60, 4),
];

Future<void> _seedBeerShop(AppDatabase db) async {
  final now = DateTime.now().toUtc();
  final today = DateTime.utc(now.year, now.month, now.day);
  String id(int i) => 'SHOP-${(i + 1).toString().padLeft(3, '0')}';
  String barcode(int i) => '89010630${(1001 + i * 7).toString().padLeft(5, '0')}';

  await db.batch((b) {
    for (var i = 0; i < _beerShop.length; i++) {
      final m = _beerShop[i];
      b.insert(db.cachedMaterials, CachedMaterialsCompanion.insert(
        id: id(i), barcode: barcode(i), name: m.$1, manufacturer: Value(m.$2), category: m.$3,
        packing: m.$4, saleRate: m.$5, taxPercent: 0, stockQty: Value(m.$6), isActive: const Value(true),
        createdAt: Value(now), updatedAt: Value(now), lastSyncedAt: Value(now),
      ));
      b.insert(db.cachedInventoryStocks, CachedInventoryStocksCompanion.insert(
        materialId: id(i), barcode: barcode(i), name: m.$1, category: m.$3, qtyOnHand: m.$6,
        reorderLevel: const Value(24), updatedAt: Value(now),
      ));
    }

    // A one-day permit so the bill header isn't empty (synthetic, not a person).
    b.insert(db.cachedLicenseHolders, CachedLicenseHoldersCompanion.insert(
      id: 'DAY-0001', permitNo: '0001', name: 'ONE DAY PERMIT', createdAt: Value(now), updatedAt: Value(now),
    ));

    // A year of bills, growing steadily, with a good last week; busier on Fri/Sat. Each bill is 1–3 lines.
    var seq = 1;
    for (var d = 364; d >= 0; d--) {
      final day = today.subtract(Duration(days: d));
      final busy = day.weekday == DateTime.friday || day.weekday == DateTime.saturday;
      final bills = ((busy ? 34 : 24) * (0.45 + 0.55 * (364 - d) / 364) * (d < 7 ? 1.18 : 1)).round();
      for (var k = 0; k < bills; k++) {
        final billId = 'shop-sale-$d-$k';
        final at = DateTime.utc(day.year, day.month, day.day, 5 + (k * 13) % 12, (k * 17) % 60);
        final pay = const ['UPI', 'Cash', 'UPI', 'Cash', 'Card'][(k + d) % 5];
        var total = 0.0;
        final lineCount = 1 + (k + d) % 3;
        for (var l = 0; l < lineCount; l++) {
          // Weight towards the fast movers (earlier in the list within each pass).
          final i = ((k * 5 + l * 3 + d) % (_beerShop.length + 6)) % _beerShop.length;
          final m = _beerShop[i];
          final qty = m.$3 == 'Wine' ? 1 : 1 + (k + l) % 4;
          final amount = qty * m.$5;
          total += amount;
          b.insert(db.cachedSaleLineItems, CachedSaleLineItemsCompanion.insert(
            id: '$billId-$l', salesBillId: billId, materialId: Value(id(i)), barcodeNo: barcode(i),
            materialType: m.$3, materialName: m.$1, batchNo: const Value('-'), packing: Value(m.$4),
            quantity: qty, qtyCase: const Value(0), rate: m.$5, discountPercent: 0, discountAmount: 0,
            taxPercent: 0, taxAmount: 0, amount: amount, lineNumber: l + 1,
          ));
        }
        b.insert(db.cachedSalesBills, CachedSalesBillsCompanion.insert(
          id: billId, billNo: 'CS-2627-${(seq++).toString().padLeft(6, '0')}', payMode: pay, status: 'paid',
          totalAmount: total, balanceDue: 0, totalTax: 0, syncStatus: const Value('synced'),
          billDate: day, createdAt: Value(at), updatedAt: Value(at),
        ));
      }
    }
  });
}
