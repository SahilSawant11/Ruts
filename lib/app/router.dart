import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/inventory/presentation/screens/inventory_screen.dart';
import '../features/masters/presentation/screens/all_masters_screen.dart';
import '../features/masters/presentation/screens/material_master_screen.dart';
import '../features/masters/presentation/screens/supplier_master_screen.dart';
import '../features/purchase/presentation/screens/purchase_bill_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/sales/presentation/screens/sales_billing_screen.dart';
import '../shared/widgets/layout/app_shell.dart';

/// StatefulShellRoute keeps the sidebar/header/status bar (built once
/// in AppShell) alive across navigation — only the active branch's
/// content swaps. Each branch also keeps its own Navigator, so a
/// screen's local state (e.g. the Sales cart) survives switching away
/// and back, instead of resetting every time like a plain GoRoute would.
///
/// Branch order here MUST match `_branchMeta` in app_shell.dart.
final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/sales', builder: (context, state) => const SalesBillingScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/purchase', builder: (context, state) => const PurchaseBillScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/supplier', builder: (context, state) => const SupplierMasterScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/material', builder: (context, state) => const MaterialMasterScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/masters', builder: (context, state) => const AllMastersScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/inventory', builder: (context, state) => const InventoryScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
        ]),
      ],
    ),
  ],
);
