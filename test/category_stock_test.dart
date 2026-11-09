import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/inventory/data/category_stock.dart';
import 'package:pos_app/features/inventory/data/inventory_providers.dart';
import 'package:pos_app/features/inventory/data/models/inventory_overview_item.dart';
import 'package:pos_app/features/inventory/presentation/widgets/category_bottle_gauges.dart';

InventoryOverviewItem item(String id, String category, int qty, {String packing = '750 ML'}) => InventoryOverviewItem(
      materialId: id,
      barcode: id,
      name: 'Item $id',
      manufacturer: 'Maker',
      category: category,
      packing: packing,
      qtyOnHand: qty,
      reorderLevel: 10,
      saleRate: 100,
    );

void main() {
  final items = [
    item('W1', 'Whisky', 40),
    item('W2', 'Whisky', 5), // low
    item('W3', 'Whisky', 0), // out
    item('W4', 'Whisky', 25),
    item('B1', 'Beer', 3), // low
    item('B2', 'Beer', 0), // out
    item('B3', 'Beer', 50, packing: '650 ML'), // healthy only because 650 ML threshold is 2
    item('R1', 'Rum', 30),
  ];
  int threshold(String? c, String? p) => p == '650 ML' ? 2 : 10;

  test('per-category health uses the low-stock rules; biggest first', () {
    final s = summarizeCategories(items, threshold);
    expect(s.map((c) => c.category), ['Whisky', 'Beer', 'Rum']);

    final whisky = s[0];
    expect((whisky.products, whisky.healthy, whisky.low, whisky.out, whisky.bottles), (4, 2, 1, 1, 70));
    expect(whisky.fill, 0.5);
    expect(whisky.health, CategoryHealth.watch);

    final beer = s[1];
    expect((beer.healthy, beer.low, beer.out), (1, 1, 1));
    expect(beer.health, CategoryHealth.watch); // 1/3 ≈ 0.33

    expect(s[2].health, CategoryHealth.good);
    expect(summarizeCategories([item('X', 'Gin', 0)], threshold).single.health, CategoryHealth.critical);
  });

  test('caps the number of bottles', () {
    final many = [for (var i = 0; i < 12; i++) item('M$i', 'Cat$i', 20)];
    expect(summarizeCategories(many, threshold), hasLength(8));
  });

  testWidgets('clicking a bottle filters the table to that category, again clears it', (tester) async {
    tester.view.physicalSize = const Size(1400, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      inventoryOverviewProvider.overrideWith((ref) async => items),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light, home: const Scaffold(body: CategoryBottleGauges())),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Whisky'), findsOneWidget);
    expect(find.text('2/4 healthy'), findsOneWidget);
    expect(find.text('1 all healthy'), findsOneWidget);

    await tester.tap(find.text('Beer'));
    await tester.pump();
    expect(container.read(inventoryCategoryFilterProvider), 'Beer');
    await tester.tap(find.text('Beer'));
    await tester.pump();
    expect(container.read(inventoryCategoryFilterProvider), isNull);
    expect(tester.takeException(), isNull);
  });
}
