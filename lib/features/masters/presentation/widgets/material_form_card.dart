import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../../sales/data/models/material_dto.dart';
import '../../data/masters_providers.dart';
import '../../data/models/save_material_request.dart';
import '../material_browser_controller.dart';

/// Single-record material inspector & editor form.
/// In split-view mode, it docks as an Apple-style inspector pane with
/// visual grouping (Identification, Classification, Pricing) and
/// sticky action controls.
class MaterialFormCard extends ConsumerStatefulWidget {
  const MaterialFormCard({super.key, this.isSplitView = false});

  final bool isSplitView;

  @override
  ConsumerState<MaterialFormCard> createState() => _MaterialFormCardState();
}

class _MaterialFormCardState extends ConsumerState<MaterialFormCard> {
  final _id = TextEditingController();
  final _barcode = TextEditingController();
  final _name = TextEditingController();
  final _saleRate = TextEditingController();
  final _taxPercent = TextEditingController();
  String _manufacturer = '';
  String _category = '';
  String _packing = '';
  bool _isActive = true;

  int? _lastIndex;
  bool? _lastIsNew;

  @override
  void dispose() {
    _id.dispose();
    _barcode.dispose();
    _name.dispose();
    _saleRate.dispose();
    _taxPercent.dispose();
    super.dispose();
  }

  void _populateFrom(MaterialDto? material) {
    _id.text = material?.id ?? '';
    _barcode.text = material?.barcode ?? '';
    _name.text = material?.name ?? '';
    _packing = material?.packing ?? '';
    _saleRate.text = material != null ? material.saleRate.toString() : '0';
    _taxPercent.text = material != null ? material.taxPercent.toString() : '5';
    _manufacturer = material?.manufacturer ?? '';
    _category = material?.category ?? '';
    _isActive = material?.isActive ?? true;
  }

  Future<void> _save() async {
    final browser = ref.read(materialBrowserProvider);

    if (_id.text.trim().isEmpty) {
      _showSnack('SCM Code is required.', isError: true);
      return;
    }
    if (_name.text.trim().isEmpty) {
      _showSnack('Name is required.', isError: true);
      return;
    }

    ref.read(materialBrowserProvider.notifier).setSaving(true);
    try {
      final request = SaveMaterialRequest(
        id: _id.text.trim(),
        barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
        name: _name.text.trim(),
        manufacturer: _manufacturer,
        category: _category,
        packing: _packing.trim(),
        saleRate: double.tryParse(_saleRate.text) ?? 0,
        taxPercent: double.tryParse(_taxPercent.text) ?? 0,
        isActive: _isActive,
      );

      final repo = ref.read(mastersRepositoryProvider);
      final saved = browser.isNew
          ? await repo.createMaterial(request)
          : await repo.updateMaterial(browser.current!.id, request);

      final freshList = await repo.getMaterials();
      ref.read(materialBrowserProvider.notifier).afterSave(freshList, saved.id);
      ref.invalidate(materialsListProvider);

      if (!mounted) return;
      _showSnack('Material saved successfully.');
    } on ApiException catch (e) {
      ref.read(materialBrowserProvider.notifier).setSaving(false);
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialsListProvider);
    final manufacturersAsync = ref.watch(manufacturersListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final packingsAsync = ref.watch(packingsListProvider);

    ref.listen(materialsListProvider, (previous, next) {
      next.whenData((materials) => ref.read(materialBrowserProvider.notifier).syncList(materials));
    });

    final browser = ref.watch(materialBrowserProvider);
    if (browser.materials.isEmpty && materialsAsync.hasValue && materialsAsync.value!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(materialBrowserProvider.notifier).syncList(materialsAsync.value!);
      });
    }

    if (_lastIndex != browser.index || _lastIsNew != browser.isNew) {
      _lastIndex = browser.index;
      _lastIsNew = browser.isNew;
      _populateFrom(browser.current);
    }

    final editable = browser.isEditing || browser.isNew;
    final idEditable = browser.isNew; // SCM Code can only be set during creation

    final manufacturers = manufacturersAsync.maybeWhen(
      data: (items) => items.map((item) => item.name).toList(),
      orElse: () => const <String>[],
    );
    final categories = categoriesAsync.maybeWhen(
      data: (items) => items.map((item) => item.name).toList(),
      orElse: () => const <String>[],
    );
    final packings = packingsAsync.maybeWhen(
      data: (items) => items.map((item) => item.name).toList(),
      orElse: () => const <String>[],
    );

    final manufacturerValue = _manufacturer.isNotEmpty
        ? _manufacturer
        : manufacturers.isNotEmpty
            ? manufacturers.first
            : '';
    if (_manufacturer != manufacturerValue) {
      _manufacturer = manufacturerValue;
    }

    final categoryValue = _category.isNotEmpty
        ? _category
        : categories.isNotEmpty
            ? categories.first
            : 'Beer';
    if (_category != categoryValue) {
      _category = categoryValue;
    }

    final packingValue = _packing.isNotEmpty
        ? _packing
        : packings.isNotEmpty
            ? packings.first
            : '750 ML';
    if (_packing != packingValue) {
      _packing = packingValue;
    }

    final dropdownPackings = (_packing.isNotEmpty && !packings.contains(_packing))
        ? [_packing, ...packings]
        : packings;

    return materialsAsync.when(
      loading: () => const AppCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (error, _) => AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: Text('Could not load materials: $error', style: AppTypography.bodyMuted)),
        ),
      ),
      data: (materials) {
        final cardContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inspector Header
            _buildHeader(context, browser, materials, editable),
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: AppColors.borderFor(context)),
            const SizedBox(height: AppSpacing.sm),

            // Form Content
            if (widget.isSplitView)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _buildFormSections(
                    context,
                    browser,
                    editable,
                    idEditable,
                    manufacturers,
                    categories,
                    dropdownPackings,
                  ),
                ),
              )
            else
              _buildFormSections(
                context,
                browser,
                editable,
                idEditable,
                manufacturers,
                categories,
                dropdownPackings,
              ),

            // Sticky Bottom Action Bar
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: AppColors.borderFor(context)),
            const SizedBox(height: AppSpacing.sm),
            _buildActionBar(context, browser, materials, editable),
          ],
        );

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: widget.isSplitView
              ? SizedBox(height: double.infinity, child: cardContent)
              : cardContent,
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    MaterialBrowserState browser,
    List<MaterialDto> materials,
    bool editable,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: browser.isNew
                ? AppColors.success.withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            browser.isNew ? Icons.add_circle_outline_rounded : Icons.liquor_rounded,
            size: 20,
            color: browser.isNew ? AppColors.success : AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                browser.isNew ? 'New Material Record' : (_name.text.isEmpty ? 'Material Inspector' : _name.text),
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sectionTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                browser.isNew
                    ? 'Fill in SCM code from client sheet'
                    : 'SCM Code: ${_id.text.isEmpty ? '—' : _id.text} · ${browser.index + 1} of ${materials.length}',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: AppColors.textMutedFor(context)),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        // Active / Inactive Pill Toggle
        InkWell(
          onTap: editable ? () => setState(() => _isActive = !_isActive) : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _isActive
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: _isActive ? AppColors.success : AppColors.danger,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isActive ? Icons.check_circle_rounded : Icons.block_rounded,
                  size: 14,
                  color: _isActive ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 5),
                Text(
                  _isActive ? 'Active' : 'Inactive',
                  style: AppTypography.caption.copyWith(
                    color: _isActive ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (editable) ...[
                  const SizedBox(width: 3),
                  Icon(
                    Icons.edit_outlined,
                    size: 12,
                    color: _isActive ? AppColors.success : AppColors.danger,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!browser.isNew) ...[
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: 'Previous Material',
            icon: const Icon(Icons.chevron_left_rounded),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            onPressed: browser.hasPrev ? () => ref.read(materialBrowserProvider.notifier).prev() : null,
          ),
          IconButton(
            tooltip: 'Next Material',
            icon: const Icon(Icons.chevron_right_rounded),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            onPressed: browser.hasNext ? () => ref.read(materialBrowserProvider.notifier).next() : null,
          ),
        ],
      ],
    );
  }

  Widget _buildFormSections(
    BuildContext context,
    MaterialBrowserState browser,
    bool editable,
    bool idEditable,
    List<String> manufacturers,
    List<String> categories,
    List<String> dropdownPackings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: Identification
        _sectionLabel(context, '1. Identification & Codes', Icons.qr_code_rounded),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: AppTextField(
                label: 'SCM CODE *',
                controller: _id,
                enabled: idEditable,
                selectAllOnFocus: true,
                showPasteButton: idEditable,
                hint: idEditable ? 'e.g. SCM-10029' : null,
                suffix: idEditable
                    ? null
                    : Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textMutedFor(context)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 4,
              child: AppTextField(
                label: 'BARCODE',
                controller: _barcode,
                enabled: editable,
                hint: 'Same as SCM code if blank',
                selectAllOnFocus: true,
                showPasteButton: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'DISPLAY NAME *',
          controller: _name,
          enabled: editable,
          hint: 'e.g. Jack Daniel\'s Old No. 7 Tennessee Whiskey',
        ),

        const SizedBox(height: AppSpacing.md),

        // Section 2: Classification
        _sectionLabel(context, '2. Classification & Packaging', Icons.category_outlined),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: editable
                  ? AppDropdown<String>(
                      label: 'CATEGORY',
                      items: categories,
                      itemLabel: (v) => v,
                      value: categories.contains(_category) ? _category : null,
                      hint: categories.isEmpty ? 'Add categories' : null,
                      onChanged: categories.isEmpty ? null : (v) => setState(() => _category = v ?? _category),
                    )
                  : AppTextField(label: 'CATEGORY', hint: _category, enabled: false),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 4,
              child: editable
                  ? AppDropdown<String>(
                      label: 'PACKING',
                      items: dropdownPackings,
                      itemLabel: (v) => v,
                      value: dropdownPackings.contains(_packing) ? _packing : null,
                      hint: dropdownPackings.isEmpty ? 'Add packings' : null,
                      onChanged: dropdownPackings.isEmpty ? null : (v) => setState(() => _packing = v ?? _packing),
                    )
                  : AppTextField(label: 'PACKING', hint: _packing, enabled: false),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        editable
            ? AppDropdown<String>(
                label: 'MANUFACTURER / BRAND HOUSE',
                items: manufacturers,
                itemLabel: (v) => v,
                value: manufacturers.contains(_manufacturer) ? _manufacturer : null,
                hint: manufacturers.isEmpty ? 'Add manufacturer' : null,
                onChanged: manufacturers.isEmpty ? null : (v) => setState(() => _manufacturer = v ?? _manufacturer),
              )
            : AppTextField(label: 'MANUFACTURER', hint: _manufacturer, enabled: false),

        const SizedBox(height: AppSpacing.md),

        // Section 3: Pricing & Inventory
        _sectionLabel(context, '3. Pricing & Stock Rates', Icons.currency_rupee_rounded),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: AppTextField(
                label: 'SALE RATE (₹)',
                controller: _saleRate,
                enabled: editable,
                hint: '0.00',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: AppTextField(
                label: 'GST SLAB %',
                controller: _taxPercent,
                enabled: editable,
                hint: '5',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: AppTextField(
                label: 'CURRENT STOCK',
                hint: browser.current != null ? '${browser.current!.stockQty} units' : '—',
                enabled: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTypography.label.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    MaterialBrowserState browser,
    List<MaterialDto> materials,
    bool editable,
  ) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runAlignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        SecondaryButton(
          label: 'New Record',
          icon: Icons.add_rounded,
          onPressed: () => ref.read(materialBrowserProvider.notifier).startNew(),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!browser.isNew)
              SecondaryButton(
                label: browser.isEditing ? 'Cancel' : 'Modify',
                icon: browser.isEditing ? Icons.lock_outline_rounded : Icons.edit_outlined,
                onPressed: () {
                  if (browser.isEditing) {
                    // Revert
                    _populateFrom(browser.current);
                  }
                  ref.read(materialBrowserProvider.notifier).toggleEditing();
                },
              ),
            PrimaryButton(
              label: browser.isSaving ? 'Saving…' : (browser.isNew ? 'Create Material' : 'Save Changes'),
              icon: Icons.check_circle_outline_rounded,
              onPressed: editable && !browser.isSaving ? _save : null,
            ),
          ],
        ),
      ],
    );
  }
}
