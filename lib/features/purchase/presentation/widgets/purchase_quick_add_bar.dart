import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../masters/data/masters_providers.dart';
import '../../../sales/data/models/material_dto.dart';
import '../../domain/purchase_line_item.dart';
import '../purchase_cart_controller.dart';
import 'add_material_line_dialog.dart';

/// Comprehensive POS Quick Add Bar for the Purchase Bill screen.
/// Provides all capabilities and parameters from the OG screen:
/// - Real-time autocomplete suggestions dropdown with arrow key & Enter selection
/// - Editable Packaging with Master Packings dropdown selector
/// - Batch, Qty, Rate, Discount %, and Tax % controls
/// - Live computed line total preview
/// - Zero-tap Add Line on Enter or button click
/// - F1 (focus search), F4 (focus qty), F2 (open full dialog)
class PurchaseQuickAddBar extends ConsumerStatefulWidget {
  const PurchaseQuickAddBar({super.key});

  @override
  ConsumerState<PurchaseQuickAddBar> createState() => _PurchaseQuickAddBarState();
}

class _PurchaseQuickAddBarState extends ConsumerState<PurchaseQuickAddBar> {
  final _searchController = TextEditingController();
  final _packingController = TextEditingController();
  final _batchController = TextEditingController(text: 'B-1');
  final _qtyController = TextEditingController(text: '1');
  final _rateController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '5');

  final _searchFocusNode = FocusNode();
  final _packingFocusNode = FocusNode();
  final _batchFocusNode = FocusNode();
  final _qtyFocusNode = FocusNode();
  final _rateFocusNode = FocusNode();
  final _discountFocusNode = FocusNode();
  final _taxFocusNode = FocusNode();

  final _portalController = OverlayPortalController();
  final _layerLink = LayerLink();

  MaterialDto? _selectedMaterial;
  List<MaterialDto> _suggestions = [];
  int _highlightedSuggestionIndex = 0;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _searchController.dispose();
    _packingController.dispose();
    _batchController.dispose();
    _qtyController.dispose();
    _rateController.dispose();
    _discountController.dispose();
    _taxController.dispose();

    _searchFocusNode.dispose();
    _packingFocusNode.dispose();
    _batchFocusNode.dispose();
    _qtyFocusNode.dispose();
    _rateFocusNode.dispose();
    _discountFocusNode.dispose();
    _taxFocusNode.dispose();
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final isF1 = event.logicalKey == LogicalKeyboardKey.f1 || event.physicalKey == PhysicalKeyboardKey.f1;
    final isF2 = event.logicalKey == LogicalKeyboardKey.f2 || event.physicalKey == PhysicalKeyboardKey.f2;
    final isF4 = event.logicalKey == LogicalKeyboardKey.f4 || event.physicalKey == PhysicalKeyboardKey.f4;

    if (isF1) {
      _searchFocusNode.requestFocus();
      _searchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchController.text.length,
      );
      return true;
    } else if (isF2) {
      if (_portalController.isShowing) _portalController.hide();
      showAddMaterialLineDialog(context);
      return true;
    } else if (isF4) {
      _qtyFocusNode.requestFocus();
      _qtyController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _qtyController.text.length,
      );
      return true;
    }
    return false;
  }

  KeyEventResult _handleSearchKey(FocusNode node, KeyEvent event) {
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
          _onMaterialSelected(_suggestions[_highlightedSuggestionIndex]);
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
      final query = _searchController.text.trim();
      if (_selectedMaterial != null) {
        _submitLine();
      } else if (query.isNotEmpty) {
        _handleSearchSubmit(query);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _onSearchChanged(String query, List<MaterialDto> allMaterials) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      if (_portalController.isShowing) _portalController.hide();
      setState(() {
        _suggestions = [];
        _inlineError = null;
      });
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
      _inlineError = null;
    });

    if (!_portalController.isShowing) {
      _portalController.show();
    }
  }

  void _onMaterialSelected(MaterialDto material) {
    if (_portalController.isShowing) _portalController.hide();
    setState(() {
      _selectedMaterial = material;
      _searchController.text = material.name;
      _packingController.text = material.packing;
      _rateController.text =
          material.saleRate > 0 ? material.saleRate.toStringAsFixed(2) : '100.00';
      _taxController.text = material.taxPercent.toStringAsFixed(0);
      _discountController.text = '0';
      if (_batchController.text.trim().isEmpty) {
        _batchController.text = 'B-1';
      }
      _suggestions = [];
      _inlineError = null;
    });

    _qtyFocusNode.requestFocus();
    _qtyController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _qtyController.text.length,
    );
  }

  void _handleSearchSubmit(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    if (_portalController.isShowing) _portalController.hide();

    // 1. Try O(1) in-memory cache lookup
    final cache = ref.read(materialLookupCacheProvider);
    MaterialDto? found = cache?.findByBarcodeOrId(trimmed);

    // 2. Try match from materials list provider
    if (found == null) {
      final materialsAsync = ref.read(materialsListProvider);
      final list = materialsAsync.asData?.value ?? [];
      final matches = list.where((m) =>
          m.barcode.toLowerCase() == trimmed.toLowerCase() ||
          m.id.toLowerCase() == trimmed.toLowerCase() ||
          m.name.toLowerCase().contains(trimmed.toLowerCase()));
      if (matches.isNotEmpty) {
        found = matches.first;
      }
    }

    if (found != null) {
      _onMaterialSelected(found);
    } else {
      setState(() {
        _inlineError = 'No item matching "$trimmed". Tap F2 to create it.';
      });
    }
  }

  void _submitLine() {
    if (_selectedMaterial == null) {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _handleSearchSubmit(query);
      } else {
        setState(() => _inlineError = 'Scan or select a material first');
      }
      return;
    }

    final qty = int.tryParse(_qtyController.text.trim()) ?? 1;
    final rate = double.tryParse(_rateController.text.trim()) ?? _selectedMaterial!.saleRate;
    final discountPercent = double.tryParse(_discountController.text.trim()) ?? 0;
    final taxPercent = double.tryParse(_taxController.text.trim()) ?? _selectedMaterial!.taxPercent;
    final batch = _batchController.text.trim().isEmpty ? 'B-1' : _batchController.text.trim();
    final packing = _packingController.text.trim().isEmpty
        ? _selectedMaterial!.packing
        : _packingController.text.trim();

    final cart = ref.read(purchaseCartControllerProvider);
    final lineItem = PurchaseLineItem(
      index: cart.items.length + 1,
      materialId: _selectedMaterial!.id,
      manufacturer: _selectedMaterial!.manufacturer,
      material: _selectedMaterial!.name,
      batch: batch,
      packing: packing,
      qty: qty > 0 ? qty : 1,
      rate: rate >= 0 ? rate : 0,
      discountPercent: discountPercent >= 0 ? discountPercent : 0,
      taxPercent: taxPercent >= 0 ? taxPercent : 0,
    );

    ref.read(purchaseCartControllerProvider.notifier).addLine(lineItem);

    // Reset input for next scan
    setState(() {
      _selectedMaterial = null;
      _searchController.clear();
      _packingController.clear();
      _qtyController.text = '1';
      _discountController.text = '0';
      _inlineError = null;
      _suggestions = [];
    });

    _searchFocusNode.requestFocus();
  }

  double _computeLiveTotal() {
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 0;
    final dis = double.tryParse(_discountController.text.trim()) ?? 0;
    final tax = double.tryParse(_taxController.text.trim()) ?? 0;

    final gross = qty * rate;
    final taxable = gross - (gross * dis / 100);
    return taxable + (taxable * tax / 100);
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialsListProvider);
    final materials = materialsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <MaterialDto>[],
    );

    final packingsAsync = ref.watch(packingsListProvider);
    final packings = packingsAsync.maybeWhen(
      data: (list) => list.map((p) => p.name).toList(),
      orElse: () => <String>[],
    );

    final isDark = AppColors.isDark(context);
    final barBg = isDark ? AppColors.surfaceFor(context) : AppColors.surfaceAltFor(context);
    final borderColor = AppColors.borderFor(context);
    final liveTotal = _computeLiveTotal();

    ref.listen<PurchaseLineItem?>(purchaseEditingLineProvider, (previous, next) {
      if (next != null) {
        final match = materials.cast<MaterialDto?>().firstWhere(
          (m) => m?.id == next.materialId || m?.name.toLowerCase() == next.material.toLowerCase(),
          orElse: () => null,
        );

        setState(() {
          _selectedMaterial = match ??
              MaterialDto(
                id: next.materialId,
                barcode: '',
                name: next.material,
                manufacturer: next.manufacturer,
                category: 'General',
                packing: next.packing,
                saleRate: next.rate,
                taxPercent: next.taxPercent,
                stockQty: next.qty,
              );
          _searchController.text = next.material;
          _packingController.text = next.packing;
          _batchController.text = next.batch;
          _qtyController.text = next.qty.toString();
          _rateController.text = next.rate.toStringAsFixed(2);
          _discountController.text = next.discountPercent.toStringAsFixed(1);
          _taxController.text = next.taxPercent.toStringAsFixed(1);
          _inlineError = null;
        });

        _qtyFocusNode.requestFocus();
        _qtyController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _qtyController.text.length,
        );
        ref.read(purchaseEditingLineProvider.notifier).state = null;
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ROW 1: Full-Width Search Input with OverlayPortal Suggestions
          Row(
            children: [
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
                        border: Border.all(
                          color: _selectedMaterial != null
                              ? AppColors.primary
                              : AppColors.borderFor(context),
                          width: _selectedMaterial != null ? 1.5 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          // Purple BARCODE / SKU Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.qr_code_scanner_rounded, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'BARCODE / SKU',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Search TextField
                          Expanded(
                            child: Focus(
                              onKeyEvent: _handleSearchKey,
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                onChanged: (val) => _onSearchChanged(val, materials),
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
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  hintText: 'Scan barcode, type SCM code or material name... (F1)',
                                  hintStyle: AppTypography.bodyMuted.copyWith(
                                    fontSize: 11.5,
                                    color: AppColors.textMutedFor(context),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Selected Material Tag
                          if (_selectedMaterial != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoftFor(context),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedMaterial!.id,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedMaterial = null;
                                        _searchController.clear();
                                        _packingController.clear();
                                      });
                                      _searchFocusNode.requestFocus();
                                    },
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 13,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],

                          // Paste Button
                          IconButton(
                            icon: const Icon(Icons.content_paste_rounded, size: 15),
                            color: AppColors.textSecondaryFor(context),
                            tooltip: 'Paste from clipboard',
                            splashRadius: 14,
                            onPressed: () async {
                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                              final text = data?.text?.trim();
                              if (text != null && text.isNotEmpty) {
                                _searchController.text = text;
                                _searchController.selection =
                                    TextSelection.collapsed(offset: text.length);
                                _onSearchChanged(text, materials);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Inline Add Line Button
              PrimaryButton(
                label: 'Add Line',
                icon: Icons.add_rounded,
                dense: true,
                onPressed: _submitLine,
              ),

              const SizedBox(width: AppSpacing.xs),

              // Advanced Dialog Trigger
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                color: AppColors.textSecondaryFor(context),
                tooltip: 'Open Full Material Line Dialog (F2)',
                splashRadius: 16,
                onPressed: () {
                  if (_portalController.isShowing) _portalController.hide();
                  showAddMaterialLineDialog(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ROW 2: All OG Screen Parameters Strip
          Row(
            children: [
              // 1. PACKING Field (Editable + Master Dropdown)
              Container(
                width: 145,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.backgroundFor(context),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    Text(
                      'PACK',
                      style: AppTypography.label.copyWith(
                        fontSize: 8.5,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _packingController,
                        focusNode: _packingFocusNode,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _batchFocusNode.requestFocus(),
                        style: AppTypography.mono.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryFor(context),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'e.g. 12x750',
                          hintStyle: AppTypography.captionFor(context).copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                    // Quick Packaging Menu
                    PopupMenuButton<String>(
                      color: AppColors.surfaceFor(context),
                      tooltip: 'Select Packaging',
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 16,
                        color: AppColors.textSecondaryFor(context),
                      ),
                      splashRadius: 14,
                      onSelected: (val) {
                        setState(() => _packingController.text = val);
                        _batchFocusNode.requestFocus();
                      },
                      itemBuilder: (context) {
                        final items = packings.isNotEmpty
                            ? packings
                            : ['12x750ml', '24x375ml', '48x180ml', '1x1000ml', '12x650ml', '24x330ml'];
                        return items
                            .map((p) => PopupMenuItem<String>(
                                  value: p,
                                  height: 32,
                                  child: Text(
                                    p,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textPrimaryFor(context),
                                    ),
                                  ),
                                ))
                            .toList();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              // 2. BATCH Field
              Container(
                width: 95,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.backgroundFor(context),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    Text(
                      'BATCH',
                      style: AppTypography.label.copyWith(
                        fontSize: 8.5,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _batchController,
                        focusNode: _batchFocusNode,
                        textAlign: TextAlign.end,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _qtyFocusNode.requestFocus(),
                        style: AppTypography.mono.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryFor(context),
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              // 3. QTY Field
              Container(
                width: 75,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.backgroundFor(context),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    Text(
                      'QTY',
                      style: AppTypography.label.copyWith(
                        fontSize: 8.5,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _qtyController,
                        focusNode: _qtyFocusNode,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.end,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _rateFocusNode.requestFocus(),
                        onTap: () {
                          _qtyController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _qtyController.text.length,
                          );
                        },
                        style: AppTypography.mono.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryFor(context),
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              // 4. RATE Field
              Container(
                width: 95,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.backgroundFor(context),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    Text(
                      'RATE',
                      style: AppTypography.label.copyWith(
                        fontSize: 8.5,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: TextField(
                        controller: _rateController,
                        focusNode: _rateFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.end,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _discountFocusNode.requestFocus(),
                        onTap: () {
                          _rateController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _rateController.text.length,
                          );
                        },
                        style: AppTypography.mono.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryFor(context),
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: false,
                          prefixText: '₹',
                          prefixStyle: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              // 5. DISCOUNT % Field
              Container(
                width: 72,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.backgroundFor(context),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    Text(
                      'DIS%',
                      style: AppTypography.label.copyWith(
                        fontSize: 8.5,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: TextField(
                        controller: _discountController,
                        focusNode: _discountFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.end,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _taxFocusNode.requestFocus(),
                        style: AppTypography.mono.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryFor(context),
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              // 6. TAX % Field
              Container(
                width: 72,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.backgroundFor(context),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    Text(
                      'TAX%',
                      style: AppTypography.label.copyWith(
                        fontSize: 8.5,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: TextField(
                        controller: _taxController,
                        focusNode: _taxFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.end,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitLine(),
                        style: AppTypography.mono.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryFor(context),
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // 7. Live Computed Line Total Preview
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySoftFor(context),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LINE TOTAL:',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '₹${liveTotal.toStringAsFixed(2)}',
                      style: AppTypography.mono.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_inlineError != null) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.danger),
                const SizedBox(width: 4),
                Text(
                  _inlineError!,
                  style: AppTypography.caption.copyWith(color: AppColors.danger, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionsOverlay(BuildContext context) {
    return CompositedTransformFollower(
      link: _layerLink,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, 4),
      child: TapRegion(
        onTapOutside: (_) {
          if (_portalController.isShowing) {
            _portalController.hide();
          }
        },
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: 540,
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: AppColors.backgroundFor(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderFor(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: _suggestions.isEmpty
                  ? ListTile(
                      dense: true,
                      leading: const Icon(Icons.search_off_rounded, size: 18, color: AppColors.warning),
                      title: Text(
                        'No item found for "${_searchController.text.trim()}"',
                        style: AppTypography.body.copyWith(fontSize: 12),
                      ),
                      subtitle: const Text(
                        'Tap here to Quick-Create this item (F2)',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        _portalController.hide();
                        showAddMaterialLineDialog(context);
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.borderFor(context).withValues(alpha: 0.4),
                      ),
                      itemBuilder: (context, index) {
                        final item = _suggestions[index];
                        final isHighlighted = index == _highlightedSuggestionIndex;
                        return InkWell(
                          onTap: () => _onMaterialSelected(item),
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
                                      if (item.packing.isNotEmpty || item.manufacturer.isNotEmpty)
                                        Text(
                                          [
                                            if (item.packing.isNotEmpty) item.packing,
                                            if (item.manufacturer.isNotEmpty) item.manufacturer,
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
      ),
    );
  }
}
