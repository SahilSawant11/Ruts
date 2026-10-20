import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
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
  final _whereGranted = TextEditingController(text: 'Life Time');

  int? _lastIndex;
  bool? _lastIsNew;

  @override
  void dispose() {
    _permitNo.dispose();
    _name.dispose();
    _issuedDate.dispose();
    _whereGranted.dispose();
    super.dispose();
  }

  void _populateFrom(LicenseHolderDto? holder) {
    _permitNo.text = holder?.permitNo ?? '';
    _name.text = holder?.name ?? '';
    _issuedDate.text = holder?.issuedDate ?? '';
    _whereGranted.text = holder?.whereGranted ?? 'Life Time';
  }

  Future<void> _save() async {
    final browser = ref.read(licenseHolderBrowserProvider);

    if (_permitNo.text.trim().isEmpty) {
      _showSnack('Permit number is required.', isError: true);
      return;
    }
    if (_name.text.trim().isEmpty) {
      _showSnack('Permit holder name is required.', isError: true);
      return;
    }

    ref.read(licenseHolderBrowserProvider.notifier).setSaving(true);
    try {
      final request = SaveLicenseHolderRequest(
        permitNo: _permitNo.text.trim(),
        name: _name.text.trim(),
        issuedDate: _issuedDate.text.trim().isEmpty ? null : _issuedDate.text.trim(),
        whereGranted: _whereGranted.text.trim().isEmpty ? null : _whereGranted.text.trim(),
      );

      final repo = ref.read(mastersRepositoryProvider);
      final saved = browser.isNew
          ? await repo.createLicenseHolder(request)
          : await repo.updateLicenseHolder(browser.current!.id, request);

      final freshList = await repo.getLicenseHolders();
      ref.read(licenseHolderBrowserProvider.notifier).afterSave(freshList, saved.permitNo);
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

    if (_lastIndex != browser.index || _lastIsNew != browser.isNew) {
      _lastIndex = browser.index;
      _lastIsNew = browser.isNew;
      _populateFrom(browser.current);
    }

    final isNew = browser.isNew;
    final title = isNew ? 'Add License Holder' : 'License Holder Details';
    final subtitle = isNew
        ? 'Register a new permit holder for excise sales'
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
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'Previous permit',
                    onPressed: browser.hasPrev
                        ? () => ref.read(licenseHolderBrowserProvider.notifier).prev()
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Next permit',
                    onPressed: browser.hasNext
                        ? () => ref.read(licenseHolderBrowserProvider.notifier).next()
                        : null,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Permit No.
            AppTextField(
              label: 'Permit Number *',
              hint: 'e.g. 20598 or 0169550',
              controller: _permitNo,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Permit Holder Name
            AppTextField(
              label: 'Permit Holder Name *',
              hint: 'e.g. B J RAMA',
              controller: _name,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Issued Date
            AppTextField(
              label: 'Issued Date',
              hint: 'e.g. 24-Mar-2017',
              controller: _issuedDate,
              suffix: IconButton(
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
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
            const SizedBox(height: AppSpacing.sm),

            // Where Granted
            AppTextField(
              label: 'Where Granted / Validity',
              hint: 'e.g. Life Time',
              controller: _whereGranted,
            ),
            const SizedBox(height: AppSpacing.md),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isNew)
                  SecondaryButton(
                    label: 'New Permit',
                    icon: Icons.add_rounded,
                    onPressed: () =>
                        ref.read(licenseHolderBrowserProvider.notifier).startNew(),
                  ),
                const SizedBox(width: AppSpacing.sm),
                PrimaryButton(
                  label: browser.isSaving ? 'Saving…' : (isNew ? 'Create Permit' : 'Save Changes'),
                  icon: Icons.check_rounded,
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
