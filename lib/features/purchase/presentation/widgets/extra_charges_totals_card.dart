import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../inventory/data/inventory_providers.dart';
import '../../../masters/data/masters_providers.dart';
import '../../data/models/create_purchase_request.dart';
import '../../data/purchase_providers.dart';
import '../purchase_cart_controller.dart';
import '../purchase_form_controller.dart';

/// Settlement, extra charges and actions card for Purchase,
/// styled in the app's signature pebble card aesthetic matching PaymentCard.
class ExtraChargesTotalsCard extends ConsumerStatefulWidget {
  const ExtraChargesTotalsCard({super.key, this.compact = true});

  final bool compact;

  @override
  ConsumerState<ExtraChargesTotalsCard> createState() => _ExtraChargesTotalsCardState();
}

class _ExtraChargesTotalsCardState extends ConsumerState<ExtraChargesTotalsCard> {
  final _discountController = TextEditingController(text: '0');
  final _vatController = TextEditingController(text: '0');
  final _stampController = TextEditingController(text: '0');
  final _tcsController = TextEditingController(text: '0');
  final _loadingFreightController = TextEditingController(text: '0');

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    for (final c in [_discountController, _vatController, _stampController, _tcsController, _loadingFreightController]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.f8) {
      if (!_isSaving) {
        _save();
      }
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _clear();
      return true;
    }
    return false;
  }

  double _parse(String v) => double.tryParse(v) ?? 0;

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? AppColors.danger : AppColors.success),
    );
  }

  void _clear() {
    final cart = ref.read(purchaseCartControllerProvider);
    if (cart.isEmpty && _discountController.text == '0') return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundFor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Row(
          children: [
            Icon(Icons.clear_all_rounded, color: AppColors.danger, size: 22),
            SizedBox(width: 8),
            Text('Discard Purchase Bill?'),
          ],
        ),
        content: const Text('This will clear all entered line items and extra charges for this bill.'),
        actions: [
          SecondaryButton(label: 'Cancel', onPressed: () => Navigator.of(ctx).pop()),
          DangerButton(
            label: 'Clear Bill',
            icon: Icons.delete_outline_rounded,
            onPressed: () {
              ref.read(purchaseCartControllerProvider.notifier).clear();
              ref.read(purchaseFormControllerProvider.notifier).reset();
              for (final c in [_discountController, _vatController, _stampController, _tcsController, _loadingFreightController]) {
                c.text = '0';
              }
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final cart = ref.read(purchaseCartControllerProvider);
    final form = ref.read(purchaseFormControllerProvider);

    if (cart.isEmpty) {
      _showSnack('Add at least one material line before saving.', isError: true);
      return;
    }
    if (form.supplierId == null) {
      _showSnack('Select a distributor before saving.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final netAmount = cart.itemsAmount + form.extraCharges;

      final request = CreatePurchaseRequest(
        supplierId: form.supplierId!,
        billNo: form.billNo,
        challanNo: form.challanNo,
        noteNo: form.noteNo,
        payMode: form.payMode,
        tpNo: form.tpNo,
        tpDate: null,
        stNo: form.stNo,
        discount: form.discount,
        vat: form.vat,
        stamp: form.stamp,
        tcs: form.tcs,
        loadingFreight: form.loadingFreight,
        netAmount: netAmount,
        totalAmount: netAmount,
        lineItems: cart.items
            .map((i) => CreatePurchaseLineItemRequest(
                  materialId: i.materialId,
                  batchNo: i.batch,
                  packing: i.packing,
                  qty: i.qty,
                  rate: i.rate,
                  disPercent: i.discountPercent,
                  disAmount: i.discountAmount,
                  taxPercent: i.taxPercent,
                  taxAmount: i.taxAmount,
                  amount: i.amount,
                ))
            .toList(),
      );

      final result = await ref.read(purchaseRepositoryProvider).createPurchase(request);
      ref.invalidate(materialsListProvider);
      ref.invalidate(manufacturersListProvider);
      ref.invalidate(inventoryListProvider);
      ref.invalidate(inventoryOverviewProvider);
      ref.invalidate(inventoryManufacturerOptionsProvider);
      ref.invalidate(filteredInventoryOverviewProvider);

      ref.read(purchaseCartControllerProvider.notifier).clear();
      ref.read(purchaseFormControllerProvider.notifier).reset();
      for (final c in [_discountController, _vatController, _stampController, _tcsController, _loadingFreightController]) {
        c.text = '0';
      }

      if (!mounted) return;
      _showSnack(
        result.isPendingSync
            ? 'Purchase queued offline · ${result.lineItemCount} item(s) will sync when back online.'
            : 'Purchase saved · ${result.lineItemCount} item(s) added to inventory.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Extra Charges & Settlement',
                style: AppTypography.sectionTitle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // 2-column compact inputs
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'DISCOUNT',
                  hint: '0',
                  controller: _discountController,
                  onChanged: (v) => ref.read(purchaseFormControllerProvider.notifier).setDiscount(_parse(v)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: 'VAT',
                  hint: '0',
                  controller: _vatController,
                  onChanged: (v) => ref.read(purchaseFormControllerProvider.notifier).setVat(_parse(v)),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'STAMP DUTY',
                  hint: '0',
                  controller: _stampController,
                  onChanged: (v) => ref.read(purchaseFormControllerProvider.notifier).setStamp(_parse(v)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: 'TCS',
                  hint: '0',
                  controller: _tcsController,
                  onChanged: (v) => ref.read(purchaseFormControllerProvider.notifier).setTcs(_parse(v)),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          AppTextField(
            label: 'LOADING / FREIGHT',
            hint: '0',
            controller: _loadingFreightController,
            onChanged: (v) => ref.read(purchaseFormControllerProvider.notifier).setLoadingFreight(_parse(v)),
          ),

          const SizedBox(height: AppSpacing.md),

          // Primary Save Button
          PrimaryButton(
            label: _isSaving ? 'Saving…' : 'Save Purchase',
            shortcut: 'F8',
            icon: Icons.save_outlined,
            expand: true,
            onPressed: _isSaving ? null : _save,
          ),

          const SizedBox(height: AppSpacing.xs),

          // Clear / Discard Button
          SecondaryButton(
            label: 'Discard / Clear Bill',
            icon: Icons.clear_all_rounded,
            expand: true,
            dense: true,
            onPressed: _clear,
          ),
        ],
      ),
    );
  }
}
