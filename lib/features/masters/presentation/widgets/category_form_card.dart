import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/masters_providers.dart';
import '../../data/models/save_category_request.dart';
import '../category_browser_controller.dart';

class CategoryFormCard extends ConsumerStatefulWidget {
  const CategoryFormCard({super.key});

  @override
  ConsumerState<CategoryFormCard> createState() => _CategoryFormCardState();
}

class _CategoryFormCardState extends ConsumerState<CategoryFormCard> {
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
    final browser = ref.read(categoryBrowserProvider);
    if (_name.text.trim().isEmpty) {
      _showSnack('Category name is required.', isError: true);
      return;
    }

    ref.read(categoryBrowserProvider.notifier).setSaving(true);
    try {
      final repo = ref.read(mastersRepositoryProvider);
      final request = SaveCategoryRequest(
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      );
      final saved = browser.isNew
          ? await repo.createCategory(request)
          : await repo.updateCategory(browser.current!.name, request);
      final fresh = await repo.getCategories();
      ref.read(categoryBrowserProvider.notifier).afterSave(fresh, saved.name);
      ref.invalidate(categoriesListProvider);
      ref.invalidate(materialsListProvider);
      if (!mounted) return;
      _showSnack('Category saved.');
    } on ApiException catch (e) {
      ref.read(categoryBrowserProvider.notifier).setSaving(false);
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
    final categoriesAsync = ref.watch(categoriesListProvider);
    ref.listen(categoriesListProvider, (previous, next) {
      next.whenData((categories) => ref.read(categoryBrowserProvider.notifier).syncList(categories));
    });
    final browser = ref.watch(categoryBrowserProvider);

    if (_lastIndex != browser.index || _lastIsNew != browser.isNew) {
      _lastIndex = browser.index;
      _lastIsNew = browser.isNew;
      _populate(browser.current?.name, browser.current?.description);
    }

    final editable = browser.isEditing || browser.isNew;

    return categoriesAsync.when(
      loading: () => const AppCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (error, _) => AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: Text('Could not load categories: $error')),
        ),
      ),
      data: (categories) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SectionHeader(
                      title: 'Category Details',
                      subtitle: browser.isNew ? 'New category' : 'Record ${browser.index + 1} of ${categories.length}',
                    ),
                  ),
                  SecondaryButton(
                    label: 'New',
                    icon: Icons.add_rounded,
                    dense: true,
                    onPressed: () => ref.read(categoryBrowserProvider.notifier).startNew(),
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
                      label: 'CATEGORY NAME *',
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
                    onPressed: browser.isNew ? null : () => ref.read(categoryBrowserProvider.notifier).toggleEditing(),
                  ),
                  SecondaryButton(
                    label: 'Prev',
                    icon: Icons.chevron_left_rounded,
                    onPressed: browser.hasPrev ? () => ref.read(categoryBrowserProvider.notifier).prev() : null,
                  ),
                  SecondaryButton(
                    label: 'Next',
                    icon: Icons.chevron_right_rounded,
                    onPressed: browser.hasNext ? () => ref.read(categoryBrowserProvider.notifier).next() : null,
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
                      ref.read(categoryBrowserProvider.notifier).syncList(categories);
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
