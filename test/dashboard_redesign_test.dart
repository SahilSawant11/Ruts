import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/dashboard/data/dashboard_providers.dart';
import 'package:pos_app/features/dashboard/data/models/dashboard_summary_dto.dart';
import 'package:pos_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:pos_app/features/dashboard/presentation/widgets/kpi_row.dart';
import 'package:pos_app/features/dashboard/presentation/widgets/overall_information_card.dart';
import 'package:pos_app/features/dashboard/presentation/widgets/top_categories_card.dart';
import 'package:pos_app/features/dashboard/presentation/widgets/sales_purchase_capsule_card.dart';
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
      ),
    ],
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
    testWidgets('DashboardKpiRow displays all 4 elevated KPI cards and syncs timeframe uniformly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) async => mockSummary),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardKpiRow(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total Sales'), findsOneWidget);
      expect(find.text('Sales Return'), findsOneWidget);
      expect(find.text('Total Purchase'), findsOneWidget);
      expect(find.text('Purchase Return'), findsOneWidget);
      expect(find.text('View all'), findsNWidgets(4));
    });

    testWidgets('OverallInformationCard renders Suppliers, SCM Codes, and Low Stock', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) async => mockSummary),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OverallInformationCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Overall Information'), findsOneWidget);
      expect(find.text('Suppliers'), findsOneWidget);
      expect(find.text('SCM Codes'), findsOneWidget);
      expect(find.text('Low Stock'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('TopCategoriesCard renders dynamic categories', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) async => mockSummary),
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
      expect(find.text('Country Liquor'), findsOneWidget);
    });

    testWidgets('SalesPurchaseCapsuleCard renders side-by-side columns and time pills', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) async => mockSummary),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SalesPurchaseCapsuleCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sales & Purchase'), findsOneWidget);
      expect(find.text('Total Sale'), findsOneWidget);
      expect(find.text('Total Purchase'), findsOneWidget);
      expect(find.text('1D'), findsOneWidget);
      expect(find.text('1W'), findsOneWidget);
      expect(find.text('1M'), findsOneWidget);
      expect(find.text('1Y'), findsOneWidget);
    });

    testWidgets('TopSellingProductsCard renders ranked items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) async => mockSummary),
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
      expect(find.textContaining('64+ Sales'), findsWidgets);
    });

    testWidgets('RecentTransactionsCard renders rows and column headers', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) async => mockSummary),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RecentTransactionsCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recent Transaction'), findsOneWidget);
      expect(find.text('ID Transaction'), findsOneWidget);
      expect(find.text('Product / Detail'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('TXN-9081'), findsOneWidget);
      expect(find.text('Counter Cash Customer'), findsOneWidget);
      expect(find.text('Success'), findsOneWidget);
    });

    testWidgets('DashboardScreen renders complete assembled hierarchy without overflow', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) async => mockSummary),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardKpiRow), findsOneWidget);
      expect(find.byType(SalesPurchaseCapsuleCard), findsOneWidget);
      expect(find.byType(OverallInformationCard), findsOneWidget);
      expect(find.byType(TopCategoriesCard), findsOneWidget);
      expect(find.byType(TopSellingProductsCard), findsOneWidget);
      expect(find.byType(RecentTransactionsCard), findsOneWidget);
    });
  });
}
