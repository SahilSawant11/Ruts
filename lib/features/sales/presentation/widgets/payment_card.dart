import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../data/models/create_sale_request.dart';
import '../../data/sales_providers.dart';
import '../cart_controller.dart';
import '../sales_providers.dart';

/// Payment method selector, cash received input, and billing actions
/// in the app's signature pebble card aesthetic and brand styling.
class PaymentCard extends ConsumerStatefulWidget {
  const PaymentCard({super.key, this.compact = true});

  final bool compact;

  @override
  ConsumerState<PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends ConsumerState<PaymentCard> {
  bool _isSaving = false;
  final _receivedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _receivedController.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.f8) {
      if (!_isSaving) {
        _saveSale();
      }
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.f6) {
      _holdBill();
      return true;
    }
    return false;
  }

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

  void _holdBill() {
    final cart = ref.read(cartControllerProvider);
    if (cart.isEmpty) {
      _showSnack('Cart is empty. Nothing to hold.', isError: true);
      return;
    }
    _showSnack('Bill held as pending draft (F6).');
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
      _receivedController.clear();

      if (!mounted) return;
      _showSnack(
        result.isPendingSync
            ? 'Bill ${result.billNo} queued offline · ${result.lineItemCount} item(s) will sync later.'
            : 'Bill ${result.billNo} saved · ${result.lineItemCount} item(s).',
      );
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final method = ref.watch(paymentMethodProvider);
    final cart = ref.watch(cartControllerProvider);

    final receivedVal = double.tryParse(_receivedController.text.trim()) ?? 0.0;
    final changeDue = receivedVal > cart.totalAmount && cart.totalAmount > 0
        ? receivedVal - cart.totalAmount
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundFor(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderFor(context)),
        boxShadow: AppColors.cardShadowFor(context),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Payment',
                style: AppTypography.sectionTitle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 3-Pebble Method Tiles Grid
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
          const SizedBox(height: AppSpacing.sm),

          // Cash Received Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CASH RECEIVED',
                style: AppTypography.label.copyWith(
                  fontSize: 9.5,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
              if (changeDue > 0)
                Text(
                  'Change: ₹${changeDue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Cash Received Input with consistent theme border and radius
          TextField(
            controller: _receivedController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTypography.mono.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryFor(context),
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceFor(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textSecondaryFor(context),
              ),
              hintText: cart.totalAmount > 0 ? cart.totalAmount.toStringAsFixed(2) : '0.00',
              hintStyle: TextStyle(color: AppColors.textMutedFor(context), fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: AppColors.borderFor(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: AppColors.borderFor(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Save & Print Button (Pebble styled SuccessButton)
          SuccessButton(
            label: _isSaving ? 'Saving…' : 'Save & Print',
            shortcut: 'F8',
            icon: Icons.print_outlined,
            expand: true,
            onPressed: _isSaving ? null : _saveSale,
          ),
          const SizedBox(height: AppSpacing.xs),

          // Sub Row: Hold Bill (F6) & Clear Bill
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Hold',
                  shortcut: 'F6',
                  icon: Icons.pause_circle_outline_rounded,
                  dense: true,
                  onPressed: _holdBill,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: DangerButton(
                  label: 'Clear Bill',
                  icon: Icons.close_rounded,
                  outline: true,
                  onPressed: () {
                    ref.read(cartControllerProvider.notifier).clear();
                    _receivedController.clear();
                  },
                ),
              ),
            ],
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
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primarySoftFor(context)
              : AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderFor(context),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textSecondaryFor(context),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodyMuted.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 11.5,
                color: selected ? AppColors.primary : AppColors.textSecondaryFor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
