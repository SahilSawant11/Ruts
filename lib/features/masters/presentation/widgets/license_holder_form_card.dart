import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/masters_providers.dart';
import '../../data/models/license_holder_dto.dart';
import '../../data/models/save_license_holder_request.dart';
import '../license_holder_browser_controller.dart';

class LicenseHolderFormCard extends ConsumerStatefulWidget {
  const LicenseHolderFormCard({super.key, this.isSplitView = false});

  final bool isSplitView;

  @override
  ConsumerState<LicenseHolderFormCard> createState() => _LicenseHolderFormCardState();
}

class _LicenseHolderFormCardState extends ConsumerState<LicenseHolderFormCard> {
  final _permitNo = TextEditingController();
  final _name = TextEditingController();
  final _issuedDate = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _contactNo = TextEditingController();
  final _remark = TextEditingController();
  String _validity = LicenseHolderDto.lifetime;
  String _category = LicenseHolderDto.licenseHolder;
  String? _whereGranted;

  bool get _isBuyer => _category == LicenseHolderDto.frequentBuyer;

  int? _lastIndex;
  // Which record the form shows: reload on a different record, not just a
  // different list position (the list re-sorts after adds).
  LicenseHolderDto? _lastRecord;
  bool? _lastIsNew;

  @override
  void dispose() {
    _permitNo.dispose();
    _name.dispose();
    _issuedDate.dispose();
    _city.dispose();
    _address.dispose();
    _contactNo.dispose();
    _remark.dispose();
    super.dispose();
  }

  void _populateFrom(LicenseHolderDto? holder) {
    _permitNo.text = holder?.permitNo ?? '';
    _name.text = holder?.name ?? '';
    _issuedDate.text = holder?.issuedDate ?? '';
    _whereGranted = holder?.whereGranted;
    _city.text = holder?.city ?? '';
    _address.text = holder?.address ?? '';
    _contactNo.text = holder?.contactNo ?? '';
    _remark.text = holder?.remark ?? '';
    _validity = holder?.validity ?? LicenseHolderDto.lifetime;
    _category = holder?.category ?? LicenseHolderDto.licenseHolder;
  }

  static String? _t(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    final browser = ref.read(licenseHolderBrowserProvider);

    if (!_isBuyer && _permitNo.text.trim().isEmpty) {
      _showSnack('Permit number is required.', isError: true);
      return;
    }
    if (_name.text.trim().isEmpty) {
      _showSnack(_isBuyer ? 'Name is required.' : 'Permit holder name is required.', isError: true);
      return;
    }

    ref.read(licenseHolderBrowserProvider.notifier).setSaving(true);
    try {
      final request = SaveLicenseHolderRequest(
        permitNo: _isBuyer ? '' : _permitNo.text.trim(),
        name: _name.text.trim(),
        issuedDate: _t(_issuedDate),
        whereGranted: _whereGranted,
        city: _t(_city),
        validity: _validity,
        address: _t(_address),
        contactNo: _t(_contactNo),
        remark: _t(_remark),
        category: _category,
      );

      final repo = ref.read(mastersRepositoryProvider);
      final saved = browser.isNew
          ? await repo.createLicenseHolder(request)
          : await repo.updateLicenseHolder(browser.current!.id, request);

      final freshList = await repo.getLicenseHolders();
      ref.read(licenseHolderBrowserProvider.notifier).afterSave(freshList, saved.id);
      ref.invalidate(licenseHoldersListProvider);

      if (!mounted) return;
      _showSnack('License holder saved successfully.');
    } on ApiException catch (e) {
      ref.read(licenseHolderBrowserProvider.notifier).setSaving(false);
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } catch (e) {
      ref.read(licenseHolderBrowserProvider.notifier).setSaving(false);
      if (!mounted) return;
      _showSnack('Could not save license holder: $e', isError: true);
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
    final browser = ref.watch(licenseHolderBrowserProvider);

    final record = browser.current;
    // A different record, or fresh data for the same one while only viewing
    // (never while editing, so typed changes are kept).
    final recordChanged = record?.id != _lastRecord?.id ||
        (!identical(record, _lastRecord) && !(browser.isEditing || browser.isNew));
    if (recordChanged || (!browser.isNew && _lastIndex != browser.index) || _lastIsNew != browser.isNew) {
      _lastRecord = record;
      _lastIndex = browser.index;
      _lastIsNew = browser.isNew;
      _populateFrom(browser.current);
    }

    final isNew = browser.isNew;
    final title = isNew ? 'Add License Holder' : 'License Holder Details';
    final subtitle = isNew
        ? 'Register a new permit holder for excise sales'
        : (browser.current?.isFrequentBuyer ?? false)
            ? 'Frequent Buyer'
            : 'Permit No: ${browser.current?.permitNo ?? ''}';

    return AppCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SectionHeader(
                    title: title,
                    subtitle: subtitle,
                  ),
                ),
                if (!isNew) ...[
                  IconButton(
                    icon: const AppIcon(AppIcons.chevronLeft),
                    tooltip: 'Previous permit',
                    onPressed: browser.hasPrev
                        ? () => ref.read(licenseHolderBrowserProvider.notifier).prev()
                        : null,
                  ),
                  IconButton(
                    icon: const AppIcon(AppIcons.chevronRight),
                    tooltip: 'Next permit',
                    onPressed: browser.hasNext
                        ? () => ref.read(licenseHolderBrowserProvider.notifier).next()
                        : null,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: AppDropdown<String>(
                    label: 'Category',
                    items: LicenseHolderDto.categories,
                    itemLabel: (v) => v,
                    value: _category,
                    onChanged: (v) => setState(() => _category = v ?? _category),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppDropdown<String>(
                    label: 'Validity',
                    items: LicenseHolderDto.validities,
                    itemLabel: (v) => v,
                    value: _validity,
                    onChanged: (v) => setState(() => _validity = v ?? _validity),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            if (!_isBuyer) ...[
              AppTextField(
                label: 'Permit Number *',
                hint: 'e.g. 20598 or 0169550',
                controller: _permitNo,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            AppTextField(
              label: _isBuyer ? 'Name *' : 'Permit Holder Name *',
              hint: 'e.g. B J RAMA',
              controller: _name,
            ),
            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Issued Date',
                    hint: 'e.g. 24-Mar-2017',
                    controller: _issuedDate,
                    suffix: IconButton(
                      icon: const AppIcon(AppIcons.calendar, size: 18),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: DateTime(1950),
                          lastDate: DateTime(2050),
                        );
                        if (picked != null) {
                          const months = [
                            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                          ];
                          final formatted =
                              '${picked.day.toString().padLeft(2, '0')}-${months[picked.month - 1]}-${picked.year}';
                          setState(() => _issuedDate.text = formatted);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(label: 'City', hint: 'e.g. Pune', controller: _city),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            AppTextField(label: 'Address', controller: _address),
            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: AppTextField(label: 'Contact Number', hint: 'e.g. 98xxxxxx10', controller: _contactNo),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: AppTextField(label: 'Remark', controller: _remark),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isNew)
                  SecondaryButton(
                    label: 'New Permit',
                    icon: AppIcons.add,
                    onPressed: () =>
                        ref.read(licenseHolderBrowserProvider.notifier).startNew(),
                  ),
                const SizedBox(width: AppSpacing.sm),
                PrimaryButton(
                  label: browser.isSaving ? 'Saving…' : (isNew ? 'Create' : 'Save'),
                  icon: AppIcons.check,
                  onPressed: browser.isSaving ? null : _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
