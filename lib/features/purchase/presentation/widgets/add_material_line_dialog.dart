import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../masters/data/masters_providers.dart';
import '../../../masters/data/models/save_material_request.dart';
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
  final _lookupScopeFocusNode = FocusNode(canRequestFocus: false);
  final _lookupInputFocusNode = FocusNode();
  final _lookupController = TextEditingController();
  final _itemCodeController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _packingController = TextEditingController();
  final _batchController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _rateController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '5');

  MaterialDto? _material;
  bool _isSearching = false;
  bool _isCreating = false;
  bool _showQuickCreate = false;
  int _highlightedSuggestionIndex = 0;
  String? _error;
  String _category = '';

  void _selectMaterial(MaterialDto material) {
    setState(() {
      _material = material;
      _showQuickCreate = false;
      _highlightedSuggestionIndex = 0;
      _error = null;
      _lookupController.text = material.id;
      _taxController.text = material.taxPercent.toStringAsFixed(0);
      if (_rateController.text.trim().isEmpty || _rateController.text.trim() == '0') {
        _rateController.text = material.saleRate.toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    for (final c in [
      _lookupController,
      _itemCodeController,
      _barcodeController,
      _nameController,
      _packingController,
      _batchController,
      _qtyController,
      _rateController,
      _discountController,
      _taxController,
    ]) {
      c.dispose();
    }
    _lookupScopeFocusNode.dispose();
    _lookupInputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _lookupController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _material = null;
      _showQuickCreate = false;
      _highlightedSuggestionIndex = 0;
    });

    try {
      final material = await ref.read(purchaseRepositoryProvider).getMaterialByBarcode(query);
      setState(() {
        _material = material;
        _isSearching = false;
        _showQuickCreate = material == null;
        _highlightedSuggestionIndex = 0;
        _error = material == null ? 'No item found for "$query". Create it below and keep billing.' : null;
        if (material != null) {
          _lookupController.text = material.id;
          _taxController.text = material.taxPercent.toStringAsFixed(0);
          if (_rateController.text.trim().isEmpty || _rateController.text.trim() == '0') {
            _rateController.text = material.saleRate.toStringAsFixed(0);
          }
        } else {
          _itemCodeController.text = query;
          if (_barcodeController.text.trim().isEmpty) {
            _barcodeController.text = query;
          }
        }
      });
    } on ApiException catch (e) {
      setState(() {
        _isSearching = false;
        _error = e.message;
      });
    }
  }

  KeyEventResult _handleLookupKeyEvent(KeyEvent event, List<MaterialDto> suggestions) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (suggestions.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _highlightedSuggestionIndex = (_highlightedSuggestionIndex + 1) % suggestions.length;
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _highlightedSuggestionIndex =
            (_highlightedSuggestionIndex - 1 + suggestions.length) % suggestions.length;
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _selectMaterial(suggestions[_highlightedSuggestionIndex.clamp(0, suggestions.length - 1)]);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _createAndAddLine() async {
    final itemCode = _itemCodeController.text.trim();
    final itemName = _nameController.text.trim();
    final rate = double.tryParse(_rateController.text) ?? 0;

    if (itemCode.isEmpty) {
      setState(() => _error = 'Local item code is required for a new item.');
      return;
    }
    if (itemName.isEmpty) {
      setState(() => _error = 'Item name is required for a new item.');
      return;
    }
    if (rate <= 0) {
      setState(() => _error = 'Enter a valid rate before creating the item.');
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final created = await ref.read(mastersRepositoryProvider).createMaterial(
            SaveMaterialRequest(
              id: itemCode,
              barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
              name: itemName,
              category: _category,
              packing: _packingController.text.trim(),
              saleRate: rate,
              taxPercent: double.tryParse(_taxController.text) ?? 0,
            ),
          );
      ref.invalidate(materialsListProvider);
      _material = created;
      _showQuickCreate = false;
      _addLine();
    } on ApiException catch (e) {
      setState(() {
        _isCreating = false;
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

  VoidCallback? get _primaryAction {
    if (_isSearching || _isCreating) return null;
    if (_showQuickCreate) return _createAndAddLine;
    if (_material != null) return _addLine;
    return null;
  }

  String get _primaryLabel {
    if (_isCreating) return 'Creating...';
    return _showQuickCreate ? 'Create Item & Add Line' : 'Add Line';
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialsListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final lookupQuery = _lookupController.text.trim().toLowerCase();
    final suggestions = materialsAsync.maybeWhen(
      data: (materials) {
        if (lookupQuery.isEmpty) return const <MaterialDto>[];
        return materials.where((material) {
          final name = material.name.toLowerCase();
          final id = material.id.toLowerCase();
          final barcode = material.barcode.toLowerCase();
          return name.contains(lookupQuery) || id.contains(lookupQuery) || barcode.contains(lookupQuery);
        }).take(6).toList();
      },
      orElse: () => const <MaterialDto>[],
    );
    final hasSuggestions = suggestions.isNotEmpty;
    final safeHighlightedIndex = hasSuggestions
        ? _highlightedSuggestionIndex.clamp(0, suggestions.length - 1)
        : 0;
    final categories = categoriesAsync.maybeWhen(
      data: (items) => items.map((item) => item.name).toList(),
      orElse: () => const <String>[],
    );
    if (_category.isEmpty) {
      _category = categories.isNotEmpty ? categories.first : 'Beer';
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Purchase Line', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Focus(
                    focusNode: _lookupScopeFocusNode,
                    onKeyEvent: (_, event) => _handleLookupKeyEvent(event, suggestions),
                    child: AppTextField(
                      label: 'ITEM CODE / BARCODE',
                      hint: 'Scan or type name, code, or barcode',
                      controller: _lookupController,
                      focusNode: _lookupInputFocusNode,
                      showPasteButton: true,
                      selectAllOnFocus: true,
                      autofocus: true,
                      onChanged: (_) => setState(() {
                        _error = null;
                        _showQuickCreate = false;
                        _material = null;
                        _highlightedSuggestionIndex = 0;
                      }),
                      onSubmitted: (_) {
                        if (hasSuggestions) {
                          _selectMaterial(suggestions[safeHighlightedIndex]);
                          return;
                        }
                        if (_material != null && _primaryAction != null) {
                          _primaryAction!.call();
                          return;
                        }
                        if (!_isSearching) {
                          _search();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SecondaryButton(
                  label: _isSearching ? '...' : 'Find',
                  onPressed: _isSearching ? null : _search,
                ),
              ],
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Material(
                  color: AppColors.surfaceFor(context),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderFor(context)),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.borderFor(context)),
                      itemBuilder: (context, index) {
                        final material = suggestions[index];
                        final isHighlighted = index == safeHighlightedIndex;
                        return ListTile(
                          dense: true,
                          selected: isHighlighted,
                          selectedTileColor: AppColors.primary.withValues(alpha: 0.10),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          title: Text(
                            material.name,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryFor(context),
                            ),
                          ),
                          subtitle: Text(
                            '${material.id} · ${material.packing.isEmpty ? material.category : material.packing}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMutedFor(context),
                            ),
                          ),
                          trailing: Text(
                            '₹${material.saleRate.toStringAsFixed(0)}',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isHighlighted
                                  ? AppColors.primary
                                  : AppColors.textSecondaryFor(context),
                            ),
                          ),
                          onTap: () => _selectMaterial(material),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: AppTypography.caption.copyWith(color: AppColors.danger),
              ),
            ],
            if (_showQuickCreate) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'Quick create a new item right here.',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'LOCAL ITEM CODE *',
                      controller: _itemCodeController,
                      showPasteButton: true,
                      selectAllOnFocus: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      label: 'BARCODE',
                      controller: _barcodeController,
                      hint: 'Optional if same as code',
                      showPasteButton: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: AppTextField(
                      label: 'ITEM NAME *',
                      controller: _nameController,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 3,
                    child: AppDropdown<String>(
                      label: 'CATEGORY',
                      items: categories,
                      itemLabel: (value) => value,
                      value: categories.contains(_category) ? _category : null,
                      hint: categories.isEmpty ? 'Create categories in Category Master' : null,
                      onChanged: categories.isEmpty ? null : (value) => setState(() => _category = value ?? _category),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'PACKING',
                controller: _packingController,
                hint: 'e.g. 750 ML or 500 ML (CAN)',
              ),
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
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
            if (_material != null || _showQuickCreate) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Purchase details',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'BATCH NO.',
                      controller: _batchController,
                      hint: 'e.g. LP-2291',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      label: 'QTY',
                      controller: _qtyController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'RATE',
                      controller: _rateController,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      label: 'DIS %',
                      controller: _discountController,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      label: 'TAX %',
                      controller: _taxController,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SecondaryButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppSpacing.sm),
                PrimaryButton(
                  label: _primaryLabel,
                  onPressed: _primaryAction,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
