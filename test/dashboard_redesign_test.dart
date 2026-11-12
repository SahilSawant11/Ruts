import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/dashboard/data/dashboard_providers.dart';
import 'package:pos_app/features/dashboard/data/models/dashboard_summary_dto.dart';
import 'package:pos_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:pos_app/features/dashboard/presentation/widgets/dashboard_hero.dart';
import 'package:pos_app/features/inventory/data/inventory_providers.dart';
import 'package:pos_app/features/dashboard/presentation/widgets/top_categories_card.dart';
import 'package:pos_app/features/dashboard/presentation/widgets/sales_purchase_line_card.dart';
import 'package:pos_app/features/dashboard/presentation/widgets/top_selling_products_card.dart';
import 'package:pos_app/features/dashboard/presentation/widgets/recent_transactions_card.dart';

void main() {
  final mockSummary = DashboardSummaryDto(
    todaySales: 15400,
    totalSalesWeek: 89000,
    totalSalesMonth: 340000,
    salesDeltaPercent: 18.5,
    todayBillCount: 142,
    avgBillValue: 108.45,
    dailyTarget: 25000,
    last7Days: const [],
    categoryBreakdown: const [
      CategoryBreakdownItemDto(category: 'IMFL Spirits', amount: 54000),
      CategoryBreakdownItemDto(category: 'Beer & Cider', amount: 28500),
      CategoryBreakdownItemDto(category: 'Country Liquor', amount: 16800),
    ],
    paymentMix: const [],
    topCustomers: const [],
    transactionActivity: const [],
    totalPurchase: 180000,
    purchaseDeltaPercent: 12.0,
    salesReturnAmount: 4200,
    salesReturnDeltaPercent: -5.0,
    purchaseReturnAmount: 1200,
    purchaseReturnDeltaPercent: 0.0,
    supplierCount: 18,
    customerCount: 420,
    materialCount: 75,
    lowStockCount: 6,
    monthlyComparison: const [
      MonthlyComparisonPointDto(
        month: 'Jan',
        salesAmount: 70000,
        purchaseAmount: 40000,
      ),
      MonthlyComparisonPointDto(
        month: 'Feb',
        salesAmount: 85000,
        purchaseAmount: 45000,
      ),
    ],
    dailyComparison: const [
      MonthlyComparisonPointDto(
        month: '9 AM',
        salesAmount: 12000,
        purchaseAmount: 8000,
      ),
    ],
    weeklyComparison: const [
      MonthlyComparisonPointDto(
        month: 'Mon',
        salesAmount: 42000,
        purchaseAmount: 30000,
      ),
    ],
    topSellingItems: const [
      TopSellingItemDto(
        materialName: 'Johnnie Walker Black Label',
        manufacturer: 'Diageo',
        qty: 64,
        amount: 192000,
      ),
    ],
    recentTransactions: [
      RecentTransactionDto(
        billNo: 'TXN-9081',
        billDate: DateTime(2026, 10, 18, 14, 30),
        customerName: 'Counter Cash Customer',
        payMode: 'Cash',
        totalAmount: 3200,
        status: 'synced',
        itemDetail: 'Royal Challenge (2)',
      ),
    ],
  );

  final mockSnapshot = DashboardPeriodSnapshot(
    period: DashboardPeriod.week,
    sales: const PeriodMetric(89000, 75000),
    billCount: const PeriodMetric(142, 120),
    salesReturns: const PeriodMetric(4200, 0),
    purchases: const PeriodMetric(180000, 160000),
    purchaseReturns: const PeriodMetric(1200, 1500),
    categoryBreakdown: mockSummary.categoryBreakdown,
    topSellingItems: mockSummary.topSellingItems,
    paymentMix: const [],
  );

  group('Dashboard Summary DTO Tests', () {
    test('DashboardSummaryDto.fromJson parses extended fields correctly', () {
      final json = <String, dynamic>{
        'todaySales': 15400.0,
        'todayBillCount': 142,
        'avgBillValue': 108.45,
        'dailyTarget': 25000.0,
        'salesDeltaPercent': 18.5,
        'totalSalesWeek': 89000.0,
        'totalSalesMonth': 340000.0,
        'totalPurchase': 180000.0,
        'supplierCount': 18,
        'materialCount': 75,
        'lowStockCount': 6,
        'monthlyComparison': [
          {'month': 'Jan', 'salesAmount': 70000.0, 'purchaseAmount': 40000.0},
        ],
      };
      final fromJson = DashboardSummaryDto.fromJson(json);

      expect(fromJson.todaySales, 15400);
      expect(fromJson.totalSalesWeek, 89000);
      expect(fromJson.totalSalesMonth, 340000);
      expect(fromJson.totalPurchase, 180000);
      expect(fromJson.supplierCount, 18);
      expect(fromJson.materialCount, 75);
      expect(fromJson.lowStockCount, 6);
      expect(fromJson.monthlyComparison.length, 1);
      expect(fromJson.monthlyComparison.first.month, 'Jan');
    });
  });

  group('Dashboard Presentation Widgets', () {
    testWidgets('DashboardHero: period sales figure, comparison, fact cards and one period selector', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) async => mockSummary),
            dashboardSnapshotProvider.overrideWith((ref) async => mockSnapshot),
            inventoryLowStockCountProvider.overrideWith((ref) async => 6),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: DashboardHero()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sales'), findsOneWidget);
      expect(find.text('Sales Returns'), findsOneWidget);
      expect(find.text('Purchases'), findsOneWidget);
      expect(find.text('Purchase Returns'), findsOneWidget);
      // Sales figure and its real comparison (+18.7%, shown rounded).
      expect(find.text('89,000'), findsOneWidget);
      expect(find.text('↑ 19% vs previous 7 days'), findsOneWidget);
      // Products / suppliers / low stock facts.
      expect(find.text('SCM Codes'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
      expect(find.text('18 Suppliers'), findsOneWidget);
      expect(find.text('Low Stock'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      // One shared period selector.
      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('TopCategoriesCard renders dynamic categories', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) async => mockSummary),
            dashboardSnapshotProvider.overrideWith((ref) async => mockSnapshot),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TopCategoriesCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Top Categories'), findsOneWidget);
      expect(find.text('IMFL Spirits'), findsOneWidget);
      expect(find.text('Beer & Cider'), findsOneWidget);
    });

    testWidgets('SalesPurchaseLineCard: title, range pills, totals; 1D explains its range', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) async => mockSummary),
            dashboardSnapshotProvider.overrideWith((ref) async => mockSnapshot),
          ],
          child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SalesPurchaseLineCard()))),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sales & Purchase'), findsOneWidget);
      expect(find.text('Sales'), findsOneWidget);
      expect(find.text('Purchases'), findsOneWidget);
      for (final r in ['1D', '1W', '1M', '1Y']) {
        expect(find.text(r), findsOneWidget);
      }
      expect(find.text('Last 12 months'), findsOneWidget);
      await tester.tap(find.text('1D'));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('TopSellingProductsCard renders ranked items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) async => mockSummary),
            dashboardSnapshotProvider.overrideWith((ref) async => mockSnapshot),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TopSellingProductsCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Top Selling Products'), findsOneWidget);
      expect(find.text('Johnnie Walker Black Label'), findsOneWidget);
      expect(find.textContaining('64 sold'), findsWidgets);
    });

    testWidgets('RecentTransactionsCard renders rows and column headers', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) async => mockSummary),
            dashboardSnapshotProvider.overrideWith((ref) async => mockSnapshot),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RecentTransactionsCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.text('Item / Material (Qty)'), findsOneWidget);
      expect(find.text('Date & Time'), findsOneWidget);
      expect(find.text('Mode'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Royal Challenge (2)'), findsOneWidget);
    });

    testWidgets('SalesPurchaseLineCard: 12 months in a narrow card, real totals, hover shows the month', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final year = DashboardSummaryDto(
        todaySales: 0,
        todayBillCount: 0,
        avgBillValue: 0,
        dailyTarget: 0,
        last7Days: const [],
        categoryBreakdown: const [],
        paymentMix: const [],
        topSellingItems: const [],
        recentTransactions: const [],
        topCustomers: const [],
        transactionActivity: const [],
        monthlyComparison: [
          for (var i = 0; i < 12; i++)
            MonthlyComparisonPointDto(month: 'M$i', salesAmount: 50000.0 * (i + 1), purchaseAmount: 30000.0 * i),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [dashboardSummaryProvider.overrideWith((ref) async => year)],
          // A smaller window than 1366px (e.g. a laptop) gives the card ~600px.
          child: const MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 600, child: SalesPurchaseLineCard())))),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Totals are the sum of the plotted months (Indian grouping).
      expect(find.text('39,00,000'), findsOneWidget);
      expect(find.text('19,80,000'), findsOneWidget);
      // Hovering the right edge of the plot shows the last month.
      final chart = find.byType(CustomPaint).last;
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(chart));
      await gesture.moveTo(tester.getTopRight(chart) + Offset(-14, tester.getSize(chart).height / 2));
      await tester.pumpAndSettle();
      expect(find.text('M11'), findsOneWidget);
      await gesture.removePointer();
    });

    testWidgets('DashboardScreen renders complete assembled hierarchy without overflow', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) async => mockSummary),
            dashboardSnapshotProvider.overrideWith((ref) async => mockSnapshot),
            inventoryLowStockCountProvider.overrideWith((ref) async => 6),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardHero), findsOneWidget);
      expect(find.byType(SalesPurchaseLineCard), findsOneWidget);
      expect(find.byType(TopCategoriesCard), findsOneWidget);
      expect(find.byType(TopSellingProductsCard), findsOneWidget);
      expect(find.byType(RecentTransactionsCard), findsOneWidget);
    });
  });

  // Regression: the hero had a fixed 318px height and overflowed at
  // 100% (by 1px) and at larger text sizes. Every text-size preset at the
  // smallest supported window must lay out cleanly.
  for (final scale in const [0.90, 1.00, 1.12, 1.25, 1.35]) {
    testWidgets('DashboardScreen has no overflow at text size ${(scale * 100).round()}%', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1093, 614)); // 1366x768 @125%
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) async => mockSummary),
            dashboardSnapshotProvider.overrideWith((ref) async => mockSnapshot),
            inventoryLowStockCountProvider.overrideWith((ref) async => 6),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const Scaffold(body: DashboardScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
