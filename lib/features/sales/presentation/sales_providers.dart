import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../masters/data/masters_providers.dart';
import '../../masters/data/models/license_holder_dto.dart';

enum PaymentMethod { cash, card, upi }

/// Which payment method is selected in the Payment card.
final paymentMethodProvider = StateProvider<PaymentMethod>((ref) => PaymentMethod.cash);

/// Which customer id (from customersProvider) is selected on the
/// current bill. Null = walk-in / no customer selected yet.
final selectedCustomerIdProvider = StateProvider<String?>((ref) => null);

/// Explicitly selected license holder on the current bill (overrides rotation).
final selectedLicenseHolderProvider = StateProvider<LicenseHolderDto?>((ref) => null);

/// Sequential rotation index for license holders across sales.
final activeLicenseHolderIndexProvider = StateProvider<int>((ref) => 0);

/// Resolved active license holder for the current sale bill.
final activeLicenseHolderProvider = Provider<LicenseHolderDto?>((ref) {
  final explicit = ref.watch(selectedLicenseHolderProvider);
  if (explicit != null) return explicit;

  final holdersAsync = ref.watch(licenseHoldersListProvider);
  return holdersAsync.maybeWhen(
    data: (list) {
      if (list.isEmpty) return null;
      final index = ref.watch(activeLicenseHolderIndexProvider) % list.length;
      return list[index];
    },
    orElse: () => null,
  );
});

/// Bill number for the bill currently being built. Regenerated after
/// every successful save so the next bill gets a fresh number.
final billNoProvider = StateProvider<String>((ref) => _generateBillNo());

String _generateBillNo() => 'CS-${DateTime.now().millisecondsSinceEpoch}';

String generateBillNo() => _generateBillNo();
