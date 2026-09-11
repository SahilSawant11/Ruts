import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/masters_providers.dart';
import '../../data/models/save_packaging_request.dart';
import '../packaging_browser_controller.dart';

class PackagingFormCard extends ConsumerStatefulWidget {
  const PackagingFormCard({super.key});

  @override
  ConsumerState<PackagingFormCard> createState() => _PackagingFormCardState();
}

class _PackagingFormCardState extends ConsumerState<PackagingFormCard> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  int? _lastIndex;
  bool? _lastIsNew;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _populate(String? name, String? description) {
    _name.text = name ?? '';
    _description.text = description ?? '';
  }

  Future<void> _save() async {
    final browser = ref.read(packagingBrowserProvider);
    if (_name.text.trim().isEmpty) {
      _showSnack('Packaging name is required.', isError: true);
      return;
    }

    ref.read(packagingBrowserProvider.notifier).setSaving(true);
    try {
      final repo = ref.read(mastersRepositoryProvider);
      final request = SavePackagingRequest(
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      );
      final saved = browser.isNew
          ? await repo.createPacking(request)
          : await repo.updatePacking(browser.current!.name, request);
      final fresh = await repo.getPackings();
      ref.read(packagingBrowserProvider.notifier).afterSave(fresh, saved.name);
      ref.invalidate(packingsListProvider);
      ref.invalidate(materialsListProvider);
      if (!mounted) return;
      _showSnack('Packaging saved.');
    } on ApiException catch (e) {
      ref.read(packagingBrowserProvider.notifier).setSaving(false);
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
    final packingsAsync = ref.watch(packingsListProvider);
    ref.listen(packingsListProvider, (previous, next) {
      next.whenData((packings) => ref.read(packagingBrowserProvider.notifier).syncList(packings));
    });
    final browser = ref.watch(packagingBrowserProvider);

    if (_lastIndex != browser.index || _lastIsNew != browser.isNew) {
      _lastIndex = browser.index;
      _lastIsNew = browser.isNew;
      _populate(browser.current?.name, browser.current?.description);
    }

    final editable = browser.isEditing || browser.isNew;

    return packingsAsync.when(
      loading: () => const AppCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (error, _) => AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: Text('Could not load packaging: $error')),
        ),
      ),
      data: (packings) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SectionHeader(
                      title: 'Packaging Details',
                      subtitle: browser.isNew ? 'New packaging' : 'Record ${browser.index + 1} of ${packings.length}',
                    ),
                  ),
                  SecondaryButton(
                    label: 'New',
                    icon: Icons.add_rounded,
                    dense: true,
                    onPressed: () => ref.read(packagingBrowserProvider.notifier).startNew(),
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
                      label: 'PACKAGING NAME *',
                      controller: _name,
                      enabled: editable,
                      selectAllOnFocus: true,
                      showPasteButton: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 5,
                    child: AppTextField(
                      label: 'DESCRIPTION',
                      controller: _description,
                      enabled: editable,
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
                    onPressed: browser.isNew ? null : () => ref.read(packagingBrowserProvider.notifier).toggleEditing(),
                  ),
                  SecondaryButton(
                    label: 'Prev',
                    icon: Icons.chevron_left_rounded,
                    onPressed: browser.hasPrev ? () => ref.read(packagingBrowserProvider.notifier).prev() : null,
                  ),
                  SecondaryButton(
                    label: 'Next',
                    icon: Icons.chevron_right_rounded,
                    onPressed: browser.hasNext ? () => ref.read(packagingBrowserProvider.notifier).next() : null,
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
                      ref.read(packagingBrowserProvider.notifier).syncList(packings);
                      _populate(browser.current?.name, browser.current?.description);
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
