import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/reports/data/brandwise_report_provider.dart';
import 'package:pos_app/features/reports/data/counter_brandwise_report_provider.dart';
import 'package:pos_app/features/reports/data/models/brandwise_report_dto.dart';
import 'package:pos_app/features/reports/data/models/counter_brandwise_report_dto.dart';
import 'package:pos_app/features/reports/presentation/widgets/brandwise_report_table.dart';
import 'package:pos_app/features/reports/presentation/widgets/counter_brandwise_report_table.dart';

void main() {
  const qty = BrandwiseSizeQty(wine750: 2, extra: {'1000ml': 5});
  final brandwise = BrandwiseReportDto(
    reportDate: DateTime(2026, 11, 18),
    licenseHeader: 'H',
    extraSizes: const ['1000ml'],
    categories: [
      const BrandwiseCategoryDto(
        name: 'WINE',
        items: [
          BrandwiseReportItemDto(brandName: 'Big Wine', openingBalance: qty, purchase: qty, sale: qty, closingBalance: qty),
        ],
        subtotal: BrandwiseCategorySubtotal(openingBalance: qty, purchase: qty, sale: qty, closingBalance: qty),
      ),
    ],
  );
  final counter = CounterBrandwiseReportDto(
    reportDate: DateTime(2026, 11, 18),
    licenseHeader: 'H',
    extraSizes: const ['1000ml'],
    categories: [
      const CounterBrandwiseCategoryDto(
        name: 'WINE',
        items: [
          CounterBrandwiseReportItemDto(
              manufacturerName: 'Big Wine', openingBalance: qty, purchase: qty, sale: qty, closingBalance: qty),
        ],
        subtotal: CounterBrandwiseCategorySubtotal(
            openingBalance: qty, purchase: qty, sale: qty, closingBalance: qty),
      ),
    ],
  );

  Future<void> pump(WidgetTester tester, Widget table) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        brandwiseReportProvider.overrideWith((ref) async => brandwise),
        counterBrandwiseReportProvider.overrideWith((ref) async => counter),
      ],
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: table))),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('brandwise table shows an extra size column with its quantities', (tester) async {
    await pump(tester, const BrandwiseReportTable());
    expect(find.text('1000ml'), findsNWidgets(4)); // one per balance group
    expect(find.text('5'), findsNWidgets(8)); // row + subtotal × 4 groups
    expect(tester.takeException(), isNull);
  });

  testWidgets('counter brandwise table shows an extra size column', (tester) async {
    await pump(tester, const CounterBrandwiseReportTable());
    expect(find.text('1000ml'), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}
