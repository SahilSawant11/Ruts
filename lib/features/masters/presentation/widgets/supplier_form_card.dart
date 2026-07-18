import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/masters_providers.dart';
import '../../data/models/save_supplier_request.dart';
import '../../data/models/supplier_dto.dart';
import '../supplier_browser_controller.dart';

const _balanceTypes = ['Credit', 'Debit'];

/// Single-record supplier form: Prev/Next browses the real supplier
/// list, Modify unlocks editing, Save creates a new record (when
/// browsing "New") or updates the current one via the real API.
class SupplierFormCard extends ConsumerStatefulWidget {
  const SupplierFormCard({super.key});

  @override
  ConsumerState<SupplierFormCard> createState() => _SupplierFormCardState();
}

class _SupplierFormCardState extends ConsumerState<SupplierFormCard> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _contactNo = TextEditingController();
  final _email = TextEditingController();
  final _vatNo = TextEditingController();
  final _bankDetails = TextEditingController();
  final _disPercent = TextEditingController();
  final _openingBalance = TextEditingController();
  String _balanceType = 'Credit';

  int? _lastIndex;
  bool? _lastIsNew;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _contactNo.dispose();
    _email.dispose();
    _vatNo.dispose();
    _bankDetails.dispose();
    _disPercent.dispose();
    _openingBalance.dispose();
    super.dispose();
  }

  void _populateFrom(SupplierDto? supplier) {
    _name.text = supplier?.name ?? '';
    _address.text = supplier?.address ?? '';
    _contactNo.text = supplier?.contactNo ?? '';
    _email.text = supplier?.email ?? '';
    _vatNo.text = supplier?.vatNo ?? '';
    _bankDetails.text = supplier?.bankDetails ?? '';
    _disPercent.text = supplier != null ? supplier.disPercent.toString() : '0';
    _openingBalance.text = supplier != null ? supplier.openingBalance.toString() : '0';
    _balanceType = supplier?.balanceType ?? 'Credit';
  }

  Future<void> _save() async {
    final browser = ref.read(supplierBrowserProvider);

    if (_name.text.trim().isEmpty) {
      _showSnack('Name is required.', isError: true);
      return;
    }

    ref.read(supplierBrowserProvider.notifier).setSaving(true);
    try {
      final request = SaveSupplierRequest(
        name: _name.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        contactNo: _contactNo.text.trim().isEmpty ? null : _contactNo.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        vatNo: _vatNo.text.trim().isEmpty ? null : _vatNo.text.trim(),
        bankDetails: _bankDetails.text.trim().isEmpty ? null : _bankDetails.text.trim(),
        disPercent: double.tryParse(_disPercent.text) ?? 0,
        openingBalance: double.tryParse(_openingBalance.text) ?? 0,
        balanceType: _balanceType,
      );

      final repo = ref.read(mastersRepositoryProvider);
      final saved = browser.isNew
          ? await repo.createSupplier(request)
          : await repo.updateSupplier(browser.current!.id, request);

      final freshList = await repo.getSuppliers();
      ref.read(supplierBrowserProvider.notifier).afterSave(freshList, saved.id);
      ref.invalidate(suppliersListProvider);

      if (!mounted) return;
      _showSnack('Supplier saved.');
    } on ApiException catch (e) {
      ref.read(supplierBrowserProvider.notifier).setSaving(false);
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
    final suppliersAsync = ref.watch(suppliersListProvider);

    ref.listen(suppliersListProvider, (previous, next) {
      next.whenData((suppliers) => ref.read(supplierBrowserProvider.notifier).syncList(suppliers));
    });

    final browser = ref.watch(supplierBrowserProvider);

    // Repopulate the text controllers whenever the browsed record
    // actually changes (not on every rebuild).
    if (_lastIndex != browser.index || _lastIsNew != browser.isNew) {
      _lastIndex = browser.index;
      _lastIsNew = browser.isNew;
      _populateFrom(browser.current);
    }

    final editable = browser.isEditing || browser.isNew;

    return suppliersAsync.when(
      loading: () => const AppCard(child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      )),
      error: (error, _) => AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: Text('Could not load suppliers: $error')),
        ),
      ),
      data: (suppliers) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SectionHeader(
                      title: 'Supplier Information',
                      subtitle: browser.isNew
                          ? 'New supplier — Supplier No. auto-assigned on save'
                          : 'Record ${browser.index + 1} of ${suppliers.length}',
                    ),
                  ),
                  SecondaryButton(
                    label: 'New',
                    icon: Icons.add_rounded,
                    dense: true,
                    onPressed: () {
                      ref.read(supplierBrowserProvider.notifier).startNew();
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: AppTextField(label: 'NAME *', controller: _name, enabled: editable),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 3,
                    child: AppTextField(label: 'DIS %', controller: _disPercent, enabled: editable),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'ADDRESS', controller: _address, enabled: editable),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: AppTextField(label: 'CONTACT NO.', controller: _contactNo, enabled: editable)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(flex: 4, child: AppTextField(label: 'EMAIL', controller: _email, enabled: editable)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(flex: 3, child: AppTextField(label: 'VAT NO.', controller: _vatNo, enabled: editable)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: AppTextField(label: 'BANK DETAILS', controller: _bankDetails, enabled: editable)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(flex: 3, child: AppTextField(label: 'OPENING BALANCE', controller: _openingBalance, enabled: editable)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 4,
                    child: editable
                        ? AppDropdown<String>(
                            label: 'BALANCE TYPE',
                            items: _balanceTypes,
                            itemLabel: (v) => v,
                            value: _balanceType,
                            onChanged: (v) => setState(() => _balanceType = v ?? 'Credit'),
                          )
                        : AppTextField(label: 'BALANCE TYPE', hint: _balanceType, enabled: false),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1, color: AppColors.border),
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
                        : () => ref.read(supplierBrowserProvider.notifier).toggleEditing(),
                  ),
                  DangerButton(
                    label: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    onPressed: () => _showSnack('Delete isn\'t wired up yet.', isError: true),
                  ),
                  SecondaryButton(
                    label: 'Prev',
                    icon: Icons.chevron_left_rounded,
                    onPressed: browser.hasPrev ? () => ref.read(supplierBrowserProvider.notifier).prev() : null,
                  ),
                  SecondaryButton(
                    label: 'Next',
                    icon: Icons.chevron_right_rounded,
                    onPressed: browser.hasNext ? () => ref.read(supplierBrowserProvider.notifier).next() : null,
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
                      ref.read(supplierBrowserProvider.notifier).syncList(suppliers);
                      _populateFrom(browser.isNew ? (suppliers.isEmpty ? null : suppliers.first) : browser.current);
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
