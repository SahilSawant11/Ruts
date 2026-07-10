import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BillingMode { purchase, sale }

enum PaymentMethod { cash, card, upi }

/// Which billing tab (F2 Purchase / F3 Sale) is active.
final billingModeProvider = StateProvider<BillingMode>((ref) => BillingMode.sale);

/// Which payment method is selected in the Payment card.
final paymentMethodProvider = StateProvider<PaymentMethod>((ref) => PaymentMethod.cash);
