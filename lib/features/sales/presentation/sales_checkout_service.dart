import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/local/material_lookup_cache.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../inventory/data/inventory_providers.dart';
import '../../masters/data/masters_providers.dart';
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

      final activeHolder = ref.read(activeLicenseHolderProvider);

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
      ref.read(billNoProvider.notifier).state = generateBillNo();
      ref.read(selectedCustomerIdProvider.notifier).state = null;

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

      return result;
    } finally {
      _isProcessing = false;
    }
  }
}

final salesCheckoutServiceProvider = Provider<SalesCheckoutService>((ref) {
  return SalesCheckoutService(ref);
});
