import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../../sales/data/models/material_dto.dart';
import '../../data/masters_providers.dart';
import '../../data/models/save_material_request.dart';
import '../material_browser_controller.dart';

/// Single-record material form: Prev/Next browses the real material
/// list, Modify unlocks editing, Save creates a new record (when
/// browsing "New") or updates the current one.
///
/// Local Item Code is the real primary key from the client's system —
/// editable only while creating a new record, locked forever after.
class MaterialFormCard extends ConsumerStatefulWidget {
  const MaterialFormCard({super.key});

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
  }

  Future<void> _save() async {
    final browser = ref.read(materialBrowserProvider);

    if (_id.text.trim().isEmpty) {
      _showSnack('Local Item Code is required.', isError: true);
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
      );

      final repo = ref.read(mastersRepositoryProvider);
      final saved = browser.isNew
          ? await repo.createMaterial(request)
          : await repo.updateMaterial(browser.current!.id, request);

      final freshList = await repo.getMaterials();
      ref.read(materialBrowserProvider.notifier).afterSave(freshList, saved.id);
      ref.invalidate(materialsListProvider);

      if (!mounted) return;
      _showSnack('Material saved.');
    } on ApiException catch (e) {
      ref.read(materialBrowserProvider.notifier).setSaving(false);
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? AppColors.danger : AppColors.success),
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

    if (_lastIndex != browser.index || _lastIsNew != browser.isNew) {
      _lastIndex = browser.index;
      _lastIsNew = browser.isNew;
      _populateFrom(browser.current);
    }

    final editable = browser.isEditing || browser.isNew;
    final idEditable = browser.isNew; // code can only be set at creation
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
      loading: () => const AppCard(child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      )),
      error: (error, _) => AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: Text('Could not load materials: $error')),
        ),
      ),
      data: (materials) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SectionHeader(
                      title: 'Material Details',
                      subtitle: browser.isNew
                          ? 'New material — type the Local Item Code from the client sheet'
                          : 'Record ${browser.index + 1} of ${materials.length}',
                    ),
                  ),
                  SecondaryButton(
                    label: 'New',
                    icon: Icons.add_rounded,
                    dense: true,
                    onPressed: () => ref.read(materialBrowserProvider.notifier).startNew(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      label: 'LOCAL ITEM CODE *',
                      controller: _id,
                      enabled: idEditable,
                      selectAllOnFocus: true,
                      showPasteButton: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      label: 'BARCODE',
                      controller: _barcode,
                      enabled: editable,
                      hint: 'Same as item code if blank',
                      selectAllOnFocus: true,
                      showPasteButton: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 5,
                    child: AppTextField(label: 'NAME *', controller: _name, enabled: editable),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: editable
                        ? AppDropdown<String>(
                            label: 'MANUFACTURER',
                            items: manufacturers,
                            itemLabel: (v) => v,
                            value: manufacturers.contains(_manufacturer) ? _manufacturer : null,
                            hint: manufacturers.isEmpty ? 'Create manufacturers in Manufacturer Master' : null,
                            onChanged: manufacturers.isEmpty ? null : (v) => setState(() => _manufacturer = v ?? _manufacturer),
                          )
                        : AppTextField(label: 'MANUFACTURER', hint: _manufacturer, enabled: false),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 3,
                    child: editable
                        ? AppDropdown<String>(
                            label: 'CATEGORY',
                            items: categories,
                            itemLabel: (v) => v,
                            value: categories.contains(_category) ? _category : null,
                            hint: categories.isEmpty ? 'Create categories in Category Master' : null,
                            onChanged: categories.isEmpty ? null : (v) => setState(() => _category = v ?? _category),
                          )
                        : AppTextField(label: 'CATEGORY', hint: _category, enabled: false),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 3,
                    child: editable
                        ? AppDropdown<String>(
                            label: 'PACKING',
                            items: dropdownPackings,
                            itemLabel: (v) => v,
                            value: dropdownPackings.contains(_packing) ? _packing : null,
                            hint: dropdownPackings.isEmpty ? 'Create packaging in Packaging Master' : null,
                            onChanged: dropdownPackings.isEmpty ? null : (v) => setState(() => _packing = v ?? _packing),
                          )
                        : AppTextField(label: 'PACKING', hint: _packing, enabled: false),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(flex: 2, child: AppTextField(label: 'SALE RATE (₹)', controller: _saleRate, enabled: editable)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(flex: 2, child: AppTextField(label: 'GST %', controller: _taxPercent, enabled: editable)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      label: 'STOCK (LEGACY)',
                      hint: browser.current?.stockQty.toString() ?? '—',
                      enabled: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Divider(height: 1, color: AppColors.borderFor(context)),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SecondaryButton(
                    label: browser.isEditing ? 'Lock' : 'Modify',
                    icon: browser.isEditing ? Icons.lock_outline_rounded : Icons.edit_outlined,
                    onPressed: browser.isNew
                        ? null
                        : () => ref.read(materialBrowserProvider.notifier).toggleEditing(),
                  ),
                  SecondaryButton(
                    label: 'Prev',
                    icon: Icons.chevron_left_rounded,
                    onPressed: browser.hasPrev ? () => ref.read(materialBrowserProvider.notifier).prev() : null,
                  ),
                  SecondaryButton(
                    label: 'Next',
                    icon: Icons.chevron_right_rounded,
                    onPressed: browser.hasNext ? () => ref.read(materialBrowserProvider.notifier).next() : null,
                  ),
                  PrimaryButton(
                    label: browser.isSaving ? 'Saving…' : 'Save',
                    icon: Icons.save_outlined,
                    onPressed: browser.isSaving ? null : _save,
                  ),
                  SecondaryButton(
                    label: 'Close',
                    icon: Icons.close_rounded,
                    onPressed: () {
                      ref.read(materialBrowserProvider.notifier).syncList(materials);
                      _populateFrom(browser.isNew ? (materials.isEmpty ? null : materials.first) : browser.current);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
