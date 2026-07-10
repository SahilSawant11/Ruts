import 'package:go_router/go_router.dart';
import '../features/sales/presentation/screens/sales_billing_screen.dart';

/// Only one route exists in this UI-first phase. Dashboard, Purchase
/// Bill, Products, etc. will be added as their screens are built.
final appRouter = GoRouter(
  initialLocation: '/sales',
  routes: [
    GoRoute(
      path: '/sales',
      builder: (context, state) => const SalesBillingScreen(),
    ),
  ],
);
