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
  await db.ensureStarterData(includeDemoData: true);
  final cache = await MaterialLookupCache.load(db);

  const owner = AppUser(id: 'snap', username: 'owner', displayName: 'Store Owner', role: UserRole.owner);
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
    currentUserProvider.overrideWithValue(owner),
  ]);
  container.read(materialLookupCacheProvider.notifier).state = cache;

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
                data: MediaQueryData(size: size, devicePixelRatio: 1),
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
