import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../cart_controller.dart';

/// Inline Barcode Scan Row: directly touches the items table below.
/// Features the brand's pebble-like styling, purple accent tokens,
/// auto-focus barcode input, Qty field, and "+ Add" button.
/// Supports F1 (focus scan) and F4 (focus qty) hotkeys.
class ScanAddItemCard extends ConsumerStatefulWidget {
  const ScanAddItemCard({super.key, this.compact = true});

  final bool compact;

  @override
  ConsumerState<ScanAddItemCard> createState() => _ScanAddItemCardState();
}

class _ScanAddItemCardState extends ConsumerState<ScanAddItemCard> {
  final _barcodeController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _barcodeFocusNode = FocusNode();
  final _qtyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _barcodeFocusNode.requestFocus());
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _barcodeController.dispose();
    _qtyController.dispose();
    _barcodeFocusNode.dispose();
    _qtyFocusNode.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.f1) {
      _barcodeFocusNode.requestFocus();
      _barcodeController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _barcodeController.text.length,
      );
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.f4) {
      _qtyFocusNode.requestFocus();
      _qtyController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _qtyController.text.length,
      );
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _barcodeController.clear();
      _qtyController.text = '1';
      ref.read(cartControllerProvider.notifier).clear();
      _barcodeFocusNode.requestFocus();
      return true;
    }
    return false;
  }

  Future<void> _submit() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;

    final qty = int.tryParse(_qtyController.text.trim()) ?? 1;
    await ref.read(cartControllerProvider.notifier).addByBarcode(barcode, qty: qty);

    _barcodeController.clear();
    _qtyController.text = '1';
    _barcodeFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final isDark = AppColors.isDark(context);

    final barBg = isDark ? AppColors.surfaceFor(context) : AppColors.surfaceFor(context);
    final borderColor = AppColors.borderFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Pebble Barcode Input Container
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundFor(context),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      // Purple BARCODE Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, size: 15, color: Colors.white),
                            SizedBox(width: 5),
                            Text(
                              'BARCODE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Input Text Field
                      Expanded(
                        child: TextField(
                          controller: _barcodeController,
                          focusNode: _barcodeFocusNode,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) {
                            if (_qtyController.text.trim() == '1') {
                              _submit();
                            } else {
                              _qtyFocusNode.requestFocus();
                            }
                          },
                          style: AppTypography.mono.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryFor(context),
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            hintText: 'Scan barcode or type item code, then press Enter...',
                            hintStyle: AppTypography.bodyMuted.copyWith(
                              fontSize: 12,
                              color: AppColors.textMutedFor(context),
                            ),
                          ),
                        ),
                      ),

                      // Trailing Actions (Scanner progress or paste)
                      if (cart.isScanning)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        )
                      else
                        IconButton(
                          icon: Icon(
                            Icons.content_paste_rounded,
                            size: 16,
                            color: AppColors.textSecondaryFor(context),
                          ),
                          tooltip: 'Paste barcode',
                          onPressed: () async {
                            final data = await Clipboard.getData(Clipboard.kTextPlain);
                            final text = data?.text?.trim();
                            if (text != null && text.isNotEmpty) {
                              _barcodeController.text = text;
                              _barcodeController.selection = TextSelection.collapsed(offset: text.length);
                              _barcodeFocusNode.requestFocus();
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Pebble Qty Field
              Container(
                width: 68,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.backgroundFor(context),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _qtyController,
                  focusNode: _qtyFocusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  onTap: () {
                    _qtyController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _qtyController.text.length,
                    );
                  },
                  style: AppTypography.mono.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryFor(context),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    hintText: 'Qty',
                    hintStyle: AppTypography.bodyMuted.copyWith(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Pebble "+ Add" Button (Purple brand style)
              SizedBox(
                height: 38,
                child: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    onTap: cart.isScanning ? null : _submit,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 17, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            '+ Add',
                            style: AppTypography.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Scan Error row
          if (cart.scanError != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cart.scanError!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.danger,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
