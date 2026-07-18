import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/models/create_sale_request.dart';
import '../../data/sales_providers.dart';
import '../cart_controller.dart';
import '../sales_providers.dart';

/// Payment method selector + the primary checkout actions.
/// "Save & Print" is the one wired all the way to the API — it builds
/// a CreateSaleRequest from the live cart and posts it.
class PaymentCard extends ConsumerStatefulWidget {
  const PaymentCard({super.key});

  @override
  ConsumerState<PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends ConsumerState<PaymentCard> {
  bool _isSaving = false;

  String _payModeLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.upi:
        return 'UPI';
    }
  }

  Future<void> _saveSale() async {
    final cart = ref.read(cartControllerProvider);
    if (cart.isEmpty) {
      _showSnack('Add at least one item before saving.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final request = CreateSaleRequest(
        billNo: ref.read(billNoProvider),
        customerId: ref.read(selectedCustomerIdProvider),
        payMode: _payModeLabel(ref.read(paymentMethodProvider)),
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

      final result = await ref.read(salesRepositoryProvider).createSale(request);

      ref.read(cartControllerProvider.notifier).clear();
      ref.read(billNoProvider.notifier).state = generateBillNo();
      ref.invalidate(todaysBillsProvider);

      if (!mounted) return;
      _showSnack('Bill ${result.billNo} saved · ${result.lineItemCount} item(s).');
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final method = ref.watch(paymentMethodProvider);
    final cart = ref.watch(cartControllerProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Payment', icon: Icons.account_balance_wallet_outlined),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _methodTile(
                  label: 'Cash',
                  icon: Icons.payments_outlined,
                  method: PaymentMethod.cash,
                  selected: method == PaymentMethod.cash,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _methodTile(
                  label: 'Card',
                  icon: Icons.credit_card_outlined,
                  method: PaymentMethod.card,
                  selected: method == PaymentMethod.card,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _methodTile(
                  label: 'UPI',
                  icon: Icons.qr_code_2_rounded,
                  method: PaymentMethod.upi,
                  selected: method == PaymentMethod.upi,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(cart.totalAmount.toStringAsFixed(0),
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: AppSpacing.md),
          SuccessButton(
            label: _isSaving ? 'Saving…' : 'Save & Print',
            shortcut: 'F8',
            icon: Icons.print_outlined,
            expand: true,
            onPressed: _isSaving ? null : _saveSale,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Print Preview',
                  icon: Icons.visibility_outlined,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SecondaryButton(
                  label: 'Hold',
                  icon: Icons.pause_circle_outline_rounded,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DangerButton(
            label: 'Close / Clear',
            icon: Icons.close_rounded,
            expand: true,
            onPressed: () => ref.read(cartControllerProvider.notifier).clear(),
          ),
        ],
      ),
    );
  }

  Widget _methodTile({
    required String label,
    required IconData icon,
    required PaymentMethod method,
    required bool selected,
  }) {
    return InkWell(
      onTap: () => ref.read(paymentMethodProvider.notifier).state = method,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 19, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.bodyMuted.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
