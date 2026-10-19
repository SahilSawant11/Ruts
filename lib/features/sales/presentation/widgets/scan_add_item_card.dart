import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../masters/data/masters_providers.dart';
import '../../data/models/material_dto.dart';
import '../../domain/sale_line_item.dart';
import '../cart_controller.dart';
import '../sales_checkout_service.dart';

/// Inline Barcode Scan Row: directly touches the items table below.
/// Features the brand's pebble-like styling, purple accent tokens,
/// auto-focus barcode input, Qty field, and "+ Add" button.
/// Supports F1 (focus scan) and F4 (focus qty) hotkeys.
/// Features instant autocomplete suggestions dropdown on typing.
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
  bool _isSubmitting = false;

  final _portalController = OverlayPortalController();
  final _layerLink = LayerLink();
  List<MaterialDto> _suggestions = [];
  int _highlightedSuggestionIndex = 0;

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
    final isF1 = event.logicalKey == LogicalKeyboardKey.f1 || event.physicalKey == PhysicalKeyboardKey.f1;
    final isF4 = event.logicalKey == LogicalKeyboardKey.f4 || event.physicalKey == PhysicalKeyboardKey.f4;
    final isEscape = event.logicalKey == LogicalKeyboardKey.escape || event.physicalKey == PhysicalKeyboardKey.escape;

    if (isF1) {
      _barcodeFocusNode.requestFocus();
      _barcodeController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _barcodeController.text.length,
      );
      return true;
    } else if (isF4) {
      _qtyFocusNode.requestFocus();
      _qtyController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _qtyController.text.length,
      );
      return true;
    } else if (isEscape) {
      if (_portalController.isShowing) {
        _portalController.hide();
        setState(() => _suggestions = []);
        return true;
      }
      _barcodeController.clear();
      _qtyController.text = '1';
      ref.read(cartControllerProvider.notifier).clear();
      _barcodeFocusNode.requestFocus();
      return true;
    }
    return false;
  }

  KeyEventResult _handleBarcodeKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (_portalController.isShowing && _suggestions.isNotEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _highlightedSuggestionIndex =
              (_highlightedSuggestionIndex + 1) % _suggestions.length;
        });
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _highlightedSuggestionIndex =
              (_highlightedSuggestionIndex - 1 + _suggestions.length) % _suggestions.length;
        });
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        if (_highlightedSuggestionIndex < _suggestions.length) {
          _onSuggestionSelected(_suggestions[_highlightedSuggestionIndex]);
          return KeyEventResult.handled;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _portalController.hide();
        setState(() => _suggestions = []);
        return KeyEventResult.handled;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_qtyController.text.trim() == '1') {
        _submit();
      } else {
        _qtyFocusNode.requestFocus();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _onBarcodeChanged(String query, List<MaterialDto> allMaterials) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      if (_portalController.isShowing) _portalController.hide();
      setState(() => _suggestions = []);
      return;
    }

    final q = trimmed.toLowerCase();
    final matches = allMaterials.where((m) =>
        m.id.toLowerCase().contains(q) ||
        m.barcode.toLowerCase().contains(q) ||
        m.name.toLowerCase().contains(q) ||
        m.packing.toLowerCase().contains(q)).take(8).toList();

    setState(() {
      _suggestions = matches;
      _highlightedSuggestionIndex = 0;
    });

    if (!_portalController.isShowing && matches.isNotEmpty) {
      _portalController.show();
    } else if (matches.isEmpty && _portalController.isShowing) {
      _portalController.hide();
    }
  }

  Future<void> _onSuggestionSelected(MaterialDto material) async {
    if (_portalController.isShowing) _portalController.hide();
    setState(() => _suggestions = []);
    _barcodeController.text = material.barcode;
    await _submit();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;

    if (_portalController.isShowing) _portalController.hide();

    _isSubmitting = true;
    try {
      final qty = int.tryParse(_qtyController.text.trim()) ?? 1;
      final added = await ref.read(cartControllerProvider.notifier).addByBarcode(barcode, qty: qty);

      _barcodeController.clear();
      _qtyController.text = '1';
      _barcodeFocusNode.requestFocus();

      if (added && mounted) {
        final cart = ref.read(cartControllerProvider);
        if (cart.isLimitReached) {
          await _triggerAutoCheckout();
        }
      }
    } finally {
      if (mounted) {
        _isSubmitting = false;
      }
    }
  }

  Future<void> _triggerAutoCheckout() async {
    try {
      final result = await ref.read(salesCheckoutServiceProvider).executeCheckout(isAuto: true);
      if (!mounted || result == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '12-bottle limit reached · Auto checkout completed for Bill ${result.billNo}!',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final isScanning = ref.watch(cartControllerProvider.select((s) => s.isScanning));
    final scanError = ref.watch(cartControllerProvider.select((s) => s.scanError));
    final materialsAsync = ref.watch(materialsListProvider);
    final materials = materialsAsync.asData?.value ?? [];
    final isDark = AppColors.isDark(context);

    ref.listen<SaleLineItem?>(salesEditingLineProvider, (previous, next) {
      if (next != null) {
        _barcodeController.text = next.barcode;
        _qtyController.text = next.qty.toString();
        _qtyFocusNode.requestFocus();
        _qtyController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _qtyController.text.length,
        );
        ref.read(salesEditingLineProvider.notifier).state = null;
      }
    });

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
              // Pebble Barcode Input Container with Autocomplete Suggestions
              Expanded(
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: OverlayPortal(
                    controller: _portalController,
                    overlayChildBuilder: (context) => _buildSuggestionsOverlay(context),
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

                          // Input Text Field with Focus & Autocomplete listener
                          Expanded(
                            child: Focus(
                              onKeyEvent: _handleBarcodeKey,
                              child: TextField(
                                controller: _barcodeController,
                                focusNode: _barcodeFocusNode,
                                onChanged: (val) => _onBarcodeChanged(val, materials),
                                textInputAction: TextInputAction.next,
                                style: AppTypography.mono.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimaryFor(context),
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  hintText: 'Scan barcode, type SCM code or item name...',
                                  hintStyle: AppTypography.bodyMuted.copyWith(
                                    fontSize: 12,
                                    color: AppColors.textMutedFor(context),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Trailing Actions (Scanner progress or paste)
                          if (isScanning)
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
                                  _onBarcodeChanged(text, materials);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
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
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
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
                    onTap: isScanning ? null : _submit,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 17, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Add',
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
          if (scanError != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    scanError,
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

  Widget _buildSuggestionsOverlay(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Positioned(
      width: 480,
      child: CompositedTransformFollower(
        link: _layerLink,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 4),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: isDark ? AppColors.surfaceFor(context) : Colors.white,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: _suggestions.isEmpty
                ? const SizedBox.shrink()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppColors.borderFor(context).withValues(alpha: 0.4),
                    ),
                    itemBuilder: (context, index) {
                      final item = _suggestions[index];
                      final isHighlighted = index == _highlightedSuggestionIndex;

                      return InkWell(
                        onTap: () => _onSuggestionSelected(item),
                        child: Container(
                          color: isHighlighted
                              ? AppColors.primarySoftFor(context)
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  item.id,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.name,
                                      style: AppTypography.body.copyWith(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimaryFor(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      [
                                        if (item.packing.isNotEmpty) item.packing,
                                        if (item.manufacturer.isNotEmpty) item.manufacturer,
                                        if (item.barcode.isNotEmpty) 'BC: ${item.barcode}',
                                      ].join(' · '),
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 10.5,
                                        color: AppColors.textSecondaryFor(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${item.saleRate.toStringAsFixed(2)}',
                                    style: AppTypography.mono.copyWith(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (item.taxPercent > 0)
                                    Text(
                                      'GST ${item.taxPercent.toStringAsFixed(0)}%',
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 9.5,
                                        color: AppColors.textMutedFor(context),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
