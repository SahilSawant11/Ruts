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
import '../../data/masters_providers.dart';
import '../../data/models/save_supplier_request.dart';
import '../../data/models/supplier_dto.dart';
import '../supplier_browser_controller.dart';

const _balanceTypes = ['Credit', 'Debit'];

class SupplierFormCard extends ConsumerStatefulWidget {
  const SupplierFormCard({super.key, this.isSplitView = false});

  final bool isSplitView;

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
      _showSnack('Supplier name is required.', isError: true);
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
      _showSnack('Supplier saved successfully.');
    } on ApiException catch (e) {
      ref.read(supplierBrowserProvider.notifier).setSaving(false);
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersListProvider);

    ref.listen(suppliersListProvider, (previous, next) {
      next.whenData((suppliers) => ref.read(supplierBrowserProvider.notifier).syncList(suppliers));
    });

    final browser = ref.watch(supplierBrowserProvider);

    if (_lastIndex != browser.index || _lastIsNew != browser.isNew) {
      _lastIndex = browser.index;
      _lastIsNew = browser.isNew;
      _populateFrom(browser.current);
    }

    final editable = browser.isEditing || browser.isNew;

    return suppliersAsync.when(
      loading: () => const AppCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (error, _) => AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: Text('Could not load suppliers: $error', style: AppTypography.bodyMuted)),
        ),
      ),
      data: (suppliers) {
        final cardContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inspector Header
            _buildHeader(context, browser, suppliers, editable),
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: AppColors.borderFor(context)),
            const SizedBox(height: AppSpacing.sm),

            // Form Sections
            if (widget.isSplitView)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _buildFormSections(context, browser, editable),
                ),
              )
            else
              _buildFormSections(context, browser, editable),

            // Sticky Bottom Action Bar
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: AppColors.borderFor(context)),
            const SizedBox(height: AppSpacing.sm),
            _buildActionBar(context, browser, suppliers, editable),
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
    SupplierBrowserState browser,
    List<SupplierDto> suppliers,
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
            browser.isNew ? Icons.add_business_rounded : Icons.local_shipping_rounded,
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
                browser.isNew ? 'New Supplier Record' : (_name.text.isEmpty ? 'Supplier Inspector' : _name.text),
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sectionTitle.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                browser.isNew
                    ? 'Enter vendor business information'
                    : 'Vendor ID: ${browser.current?.id ?? '—'} · ${browser.index + 1} of ${suppliers.length}',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: AppColors.textMutedFor(context)),
              ),
            ],
          ),
        ),
        if (!browser.isNew) ...[
          IconButton(
            tooltip: 'Previous Supplier',
            icon: const Icon(Icons.chevron_left_rounded),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            onPressed: browser.hasPrev ? () => ref.read(supplierBrowserProvider.notifier).prev() : null,
          ),
          IconButton(
            tooltip: 'Next Supplier',
            icon: const Icon(Icons.chevron_right_rounded),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            onPressed: browser.hasNext ? () => ref.read(supplierBrowserProvider.notifier).next() : null,
          ),
        ],
      ],
    );
  }

  Widget _buildFormSections(
    BuildContext context,
    SupplierBrowserState browser,
    bool editable,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: Vendor Details
        _sectionLabel(context, '1. Vendor Profile & Contact', Icons.business_outlined),
        const SizedBox(height: 8),
        AppTextField(
          label: 'SUPPLIER NAME *',
          controller: _name,
          enabled: editable,
          hint: 'e.g. United Spirits Ltd.',
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: AppTextField(
                label: 'CONTACT PHONE',
                controller: _contactNo,
                enabled: editable,
                hint: '+91 98765 43210',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 5,
              child: AppTextField(
                label: 'EMAIL ADDRESS',
                controller: _email,
                enabled: editable,
                hint: 'orders@vendor.com',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'OFFICE / WAREHOUSE ADDRESS',
          controller: _address,
          enabled: editable,
          hint: 'Plot No., Industrial Area, City',
        ),

        const SizedBox(height: AppSpacing.md),

        // Section 2: Tax & Banking
        _sectionLabel(context, '2. Tax ID & Bank Account', Icons.account_balance_outlined),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: AppTextField(
                label: 'VAT / GSTIN NO.',
                controller: _vatNo,
                enabled: editable,
                hint: '27AAAAA0000A1Z5',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 5,
              child: AppTextField(
                label: 'BANK DETAILS',
                controller: _bankDetails,
                enabled: editable,
                hint: 'Bank Name, A/C No., IFSC',
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Section 3: Financial Terms
        _sectionLabel(context, '3. Opening Balance & Terms', Icons.currency_rupee_rounded),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: AppTextField(
                label: 'OPENING BALANCE (₹)',
                controller: _openingBalance,
                enabled: editable,
                hint: '0.00',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
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
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: AppTextField(
                label: 'DISCOUNT %',
                controller: _disPercent,
                enabled: editable,
                hint: '0',
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
    SupplierBrowserState browser,
    List<SupplierDto> suppliers,
    bool editable,
  ) {
    return Row(
      children: [
        SecondaryButton(
          label: 'New Supplier',
          icon: Icons.add_rounded,
          onPressed: () => ref.read(supplierBrowserProvider.notifier).startNew(),
        ),
        const Spacer(),
        if (!browser.isNew) ...[
          SecondaryButton(
            label: browser.isEditing ? 'Cancel / Lock' : 'Modify',
            icon: browser.isEditing ? Icons.lock_outline_rounded : Icons.edit_outlined,
            onPressed: () {
              if (browser.isEditing) {
                _populateFrom(browser.current);
              }
              ref.read(supplierBrowserProvider.notifier).toggleEditing();
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        PrimaryButton(
          label: browser.isSaving ? 'Saving…' : (browser.isNew ? 'Create Supplier' : 'Save Changes'),
          icon: Icons.check_circle_outline_rounded,
          onPressed: editable && !browser.isSaving ? _save : null,
        ),
      ],
    );
  }
}
