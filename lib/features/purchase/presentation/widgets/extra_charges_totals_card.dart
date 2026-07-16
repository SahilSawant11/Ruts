import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/models/create_purchase_request.dart';
import '../../data/purchase_providers.dart';
import '../purchase_cart_controller.dart';
import '../purchase_form_controller.dart';

class ExtraChargesTotalsCard extends ConsumerStatefulWidget {
  const ExtraChargesTotalsCard({super.key});

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
  void dispose() {
    for (final c in [_discountController, _vatController, _stampController, _tcsController, _loadingFreightController]) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(String v) => double.tryParse(v) ?? 0;

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? AppColors.danger : AppColors.success),
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

      ref.read(purchaseCartControllerProvider.notifier).clear();
      ref.read(purchaseFormControllerProvider.notifier).reset();
      for (final c in [_discountController, _vatController, _stampController, _tcsController, _loadingFreightController]) {
        c.text = '0';
      }

      if (!mounted) return;
      _showSnack('Purchase saved · ${result.lineItemCount} item(s) added to inventory.');
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(purchaseCartControllerProvider);
    final form = ref.watch(purchaseFormControllerProvider);
    final netAmount = cart.itemsAmount + form.extraCharges;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: SectionHeader(title: 'Extra Charges & Totals'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'DISCOUNT',
                    controller: _discountController,
                    onChanged: (v) => ref.read(purchaseFormControllerProvider.notifier).setDiscount(_parse(v)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    label: 'VAT',
                    controller: _vatController,
                    onChanged: (v) => ref.read(purchaseFormControllerProvider.notifier).setVat(_parse(v)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    label: 'STAMP',
                    controller: _stampController,
                    onChanged: (v) => ref.read(purchaseFormControllerProvider.notifier).setStamp(_parse(v)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    label: 'TCS',
                    controller: _tcsController,
                    onChanged: (v) => ref.read(purchaseFormControllerProvider.notifier).setTcs(_parse(v)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    label: 'LOADING / FREIGHT',
                    controller: _loadingFreightController,
                    onChanged: (v) => ref.read(purchaseFormControllerProvider.notifier).setLoadingFreight(_parse(v)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Net Amount', style: AppTypography.bodyMuted),
                Text(netAmount.toStringAsFixed(0), style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            color: AppColors.totalDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount', style: AppTypography.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(netAmount.toStringAsFixed(0), style: AppTypography.h1.copyWith(color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SecondaryButton(label: 'Modify', icon: Icons.edit_outlined, onPressed: () {}),
                SecondaryButton(label: 'View', icon: Icons.visibility_outlined, onPressed: () {}),
                DangerButton(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  onPressed: () => ref.read(purchaseCartControllerProvider.notifier).clear(),
                ),
                SecondaryButton(label: 'Payments', icon: Icons.account_balance_wallet_outlined, onPressed: () {}),
                PrimaryButton(
                  label: _isSaving ? 'Saving…' : 'Save',
                  icon: Icons.save_outlined,
                  onPressed: _isSaving ? null : _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
