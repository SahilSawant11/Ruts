import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PaymentMethod { cash, card, upi }

/// Which payment method is selected in the Payment card.
final paymentMethodProvider = StateProvider<PaymentMethod>((ref) => PaymentMethod.cash);

/// Which customer id (from customersProvider) is selected on the
/// current bill. Null = walk-in / no customer selected yet.
final selectedCustomerIdProvider = StateProvider<String?>((ref) => null);

/// Bill number for the bill currently being built. Regenerated after
/// every successful save so the next bill gets a fresh number.
/// Placeholder scheme (CS-<timestamp>) until the API exposes a real
/// sequential bill-numbering endpoint.
final billNoProvider = StateProvider<String>((ref) => _generateBillNo());

String _generateBillNo() => 'CS-${DateTime.now().millisecondsSinceEpoch}';

String generateBillNo() => _generateBillNo();
