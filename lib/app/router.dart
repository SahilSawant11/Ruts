import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/inventory/presentation/screens/inventory_screen.dart';
import '../features/masters/presentation/screens/all_masters_screen.dart';
import '../features/masters/presentation/screens/material_master_screen.dart';
import '../features/masters/presentation/screens/supplier_master_screen.dart';
import '../features/purchase/presentation/screens/purchase_bill_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/sales/presentation/screens/sales_billing_screen.dart';

/// One route per module screen. All screens share the same AppShell,
/// so switching routes only swaps the body content.
final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
    GoRoute(path: '/sales', builder: (context, state) => const SalesBillingScreen()),
    GoRoute(path: '/purchase', builder: (context, state) => const PurchaseBillScreen()),
    GoRoute(path: '/supplier', builder: (context, state) => const SupplierMasterScreen()),
    GoRoute(path: '/material', builder: (context, state) => const MaterialMasterScreen()),
    GoRoute(path: '/masters', builder: (context, state) => const AllMastersScreen()),
    GoRoute(path: '/inventory', builder: (context, state) => const InventoryScreen()),
    GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
  ],
);
