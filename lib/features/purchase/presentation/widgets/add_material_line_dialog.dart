import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../sales/data/models/material_dto.dart';
import '../../data/purchase_providers.dart';
import '../../domain/purchase_line_item.dart';
import '../purchase_cart_controller.dart';

Future<void> showAddMaterialLineDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => const _AddMaterialLineDialog(),
  );
}

class _AddMaterialLineDialog extends ConsumerStatefulWidget {
  const _AddMaterialLineDialog();

  @override
  ConsumerState<_AddMaterialLineDialog> createState() => _AddMaterialLineDialogState();
}

class _AddMaterialLineDialogState extends ConsumerState<_AddMaterialLineDialog> {
  final _barcodeController = TextEditingController();
  final _batchController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _rateController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController();

  MaterialDto? _material;
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _barcodeController,
      _batchController,
      _qtyController,
      _rateController,
      _discountController,
      _taxController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _search() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final material = await ref.read(purchaseRepositoryProvider).getMaterialByBarcode(barcode);
      setState(() {
        _material = material;
        _isSearching = false;
        _error = material == null ? 'No material found for "$barcode".' : null;
        if (material != null) _taxController.text = material.taxPercent.toStringAsFixed(0);
      });
    } on ApiException catch (e) {
      setState(() {
        _isSearching = false;
        _error = e.message;
      });
    }
  }

  void _addLine() {
    final material = _material;
    if (material == null) return;

    final qty = int.tryParse(_qtyController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final discountPercent = double.tryParse(_discountController.text) ?? 0;
    final taxPercent = double.tryParse(_taxController.text) ?? 0;
    final batch = _batchController.text.trim().isEmpty ? '-' : _batchController.text.trim();

    if (qty <= 0 || rate <= 0) {
      setState(() => _error = 'Enter a valid quantity and rate.');
      return;
    }

    final line = PurchaseLineItem(
      index: 0,
      materialId: material.id,
      material: material.name,
      batch: batch,
      packing: material.packing,
      qty: qty,
      rate: rate,
      discountPercent: discountPercent,
      taxPercent: taxPercent,
    );

    ref.read(purchaseCartControllerProvider.notifier).addLine(line);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Material Line', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'BARCODE',
                    hint: 'Scan or type barcode',
                    controller: _barcodeController,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SecondaryButton(label: _isSearching ? '...' : 'Find', onPressed: _isSearching ? null : _search),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.danger)),
            ],
            if (_material != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '${_material!.name} · ${_material!.packing}',
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: AppTextField(label: 'BATCH NO.', controller: _batchController, hint: 'e.g. LP-2291')),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: AppTextField(label: 'QTY', controller: _qtyController)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: AppTextField(label: 'RATE', controller: _rateController)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: AppTextField(label: 'DIS %', controller: _discountController)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: AppTextField(label: 'TAX %', controller: _taxController)),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SecondaryButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
                const SizedBox(width: AppSpacing.sm),
                PrimaryButton(label: 'Add Line', onPressed: _material == null ? null : _addLine),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
