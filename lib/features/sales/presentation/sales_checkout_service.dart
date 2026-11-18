import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/local/material_lookup_cache.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../inventory/data/inventory_providers.dart';
import '../../../core/network/api_exception.dart';
import '../../masters/data/masters_providers.dart';
import '../../masters/data/models/license_holder_dto.dart';
import '../../masters/data/models/save_license_holder_request.dart';
import '../../reports/data/reports_providers.dart';
import '../data/models/create_sale_request.dart';
import '../data/sales_providers.dart';
import 'cart_controller.dart';
import 'sales_providers.dart';

/// Service that handles bill checkout (both manual Save & Print and
/// automatic self-checkout when the 12-bottle / 12-barcode limit is reached).
class SalesCheckoutService {
  SalesCheckoutService(this.ref);
  final Ref ref;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  Future<CreateSaleResult?> executeCheckout({bool isAuto = false}) async {
    if (_isProcessing) return null;
    final cart = ref.read(cartControllerProvider);
    if (cart.isEmpty) return null;

    _isProcessing = true;
    try {
      final payMode = switch (ref.read(paymentMethodProvider)) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.card => 'Card',
        PaymentMethod.upi => 'UPI',
      };

      final isNewPermit = ref.read(newPermitModeProvider);
      final activeHolder = isNewPermit ? await _resolveNewPermit() : ref.read(activeLicenseHolderProvider);

      final request = CreateSaleRequest(
        billNo: ref.read(billNoProvider),
        customerId: ref.read(selectedCustomerIdProvider),
        permitNo: activeHolder?.permitNo,
        permitHolderName: activeHolder?.name,
        payMode: payMode,
        taxableValue: cart.taxableValue,
        totalDiscount: cart.totalDiscount,
        totalTax: cart.totalTax,
        totalAmount: cart.totalAmount,
        balanceDue: cart.totalAmount,
        lineItems: cart.items
            .map((i) => CreateSaleLineItemRequest(
                  materialId: i.materialId,
                  barcodeNo: i.barcode,
                  materialType: i.type,
                  materialName: i.material,
                  batchNo: i.batch,
                  packing: i.pack,
                  quantity: i.qty,
                  qtyCase: 0,
                  rate: i.rate,
                  discountPercent: i.discountPercent,
                  discountAmount: i.discountAmount,
                  taxPercent: i.taxPercent,
                  taxAmount: i.taxAmount,
                  amount: i.amount,
                ))
            .toList(),
      );

      final sw = kDebugMode ? (Stopwatch()..start()) : null;
      final result = await ref.read(salesRepositoryProvider).createSale(request);
      if (kDebugMode) {
        sw!.stop();
        debugPrint('⏱ bill save (total): ${sw.elapsedMilliseconds}ms');
      }

      // Reset cart and generate next bill number
      ref.read(cartControllerProvider.notifier).clear();
      ref.invalidate(nextBillNoProvider);
      ref.read(selectedCustomerIdProvider.notifier).state = null;
      if (isNewPermit) {
        ref.read(newPermitModeProvider.notifier).state = false;
        ref.read(newPermitNameProvider.notifier).state = '';
        ref.read(newPermitNoProvider.notifier).state = '';
      }

      // Advance license holder sequentially to the next one in rotation
      final holdersList = ref.read(licenseHoldersListProvider).valueOrNull ?? [];
      if (holdersList.isNotEmpty) {
        final currentIdx = ref.read(activeLicenseHolderIndexProvider);
        ref.read(activeLicenseHolderIndexProvider.notifier).state =
            (currentIdx + 1) % holdersList.length;
      }
      ref.read(selectedLicenseHolderProvider.notifier).state = null;

      // Refresh in-memory material lookup cache with live stock after deduction
      final db = ref.read(appDatabaseProvider);
      final updatedCache = await MaterialLookupCache.load(db);
      ref.read(materialLookupCacheProvider.notifier).state = updatedCache;

      // Invalidate relevant providers
      ref.invalidate(todaysBillsProvider);
      ref.invalidate(salesReportProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(inventoryListProvider);
      ref.invalidate(inventoryOverviewProvider);
      ref.invalidate(materialsListProvider);
      // After rotation advanced, so the new holder joins from the next bill.
      if (isNewPermit) ref.invalidate(licenseHoldersListProvider);

      return result;
    } finally {
      _isProcessing = false;
    }
  }
}

extension on SalesCheckoutService {
  /// The NEW customer's permit: reuses the holder if that permit number is
  /// already on file, otherwise adds it to the License Holder master (where
  /// it joins the normal rotation).
  Future<LicenseHolderDto> _resolveNewPermit() async {
    final name = ref.read(newPermitNameProvider).trim();
    final permitNo = ref.read(newPermitNoProvider).trim();
    if (name.isEmpty || permitNo.isEmpty) {
      throw const ApiException('Enter the new customer\'s name and license number, or pick Walk-in.');
    }
    final repo = ref.read(mastersRepositoryProvider);
    final existing = (await repo.getLicenseHolders())
        .where((h) => h.permitNo.trim().toLowerCase() == permitNo.toLowerCase());
    if (existing.isNotEmpty) return existing.first;
    return repo.createLicenseHolder(SaveLicenseHolderRequest(permitNo: permitNo, name: name));
  }
}

final salesCheckoutServiceProvider = Provider<SalesCheckoutService>((ref) {
  return SalesCheckoutService(ref);
});
