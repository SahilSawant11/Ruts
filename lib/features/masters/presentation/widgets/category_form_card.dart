import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/masters_providers.dart';
import '../../data/models/save_category_request.dart';
import '../category_browser_controller.dart';

class CategoryFormCard extends ConsumerStatefulWidget {
  const CategoryFormCard({super.key, this.isSplitView = false});

  final bool isSplitView;

  @override
  ConsumerState<CategoryFormCard> createState() => _CategoryFormCardState();
}

class _CategoryFormCardState extends ConsumerState<CategoryFormCard> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  String? _lastPopulatedName;
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
      _showSnack('Category saved successfully.');
    } on ApiException catch (e) {
      ref.read(categoryBrowserProvider.notifier).setSaving(false);
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
    final categoriesAsync = ref.watch(categoriesListProvider);
    final browser = ref.watch(categoryBrowserProvider);
    categoriesAsync.whenData((categories) {
      if (categories.isNotEmpty && browser.categories.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(categoryBrowserProvider.notifier).syncList(categories);
        });
      }
    });

    final currentName = browser.current?.name;
    if (_lastPopulatedName != currentName || _lastIsNew != browser.isNew) {
      _lastPopulatedName = currentName;
      _lastIsNew = browser.isNew;
      _populate(browser.current?.name, browser.current?.description);
    }

    final editable = browser.isEditing || browser.isNew;

    return categoriesAsync.when(
      loading: () => const AppCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (error, _) => AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: Text('Could not load categories: $error', style: AppTypography.bodyMuted)),
        ),
      ),
      data: (categories) {
        final cardContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
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
                    browser.isNew ? Icons.add_circle_outline_rounded : Icons.category_rounded,
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
                        browser.isNew ? 'New Category Record' : (_name.text.isEmpty ? 'Category Details' : _name.text),
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.sectionTitle.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryFor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        browser.isNew
                            ? 'Configure beverage class & classification'
                            : 'Record ${browser.index + 1} of ${categories.length}',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(color: AppColors.textMutedFor(context)),
                      ),
                    ],
                  ),
                ),
                if (!browser.isNew) ...[
                  IconButton(
                    tooltip: 'Previous Category',
                    icon: const Icon(Icons.chevron_left_rounded),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    onPressed: browser.hasPrev ? () => ref.read(categoryBrowserProvider.notifier).prev() : null,
                  ),
                  IconButton(
                    tooltip: 'Next Category',
                    icon: const Icon(Icons.chevron_right_rounded),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    onPressed: browser.hasNext ? () => ref.read(categoryBrowserProvider.notifier).next() : null,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: AppColors.borderFor(context)),
            const SizedBox(height: AppSpacing.sm),

            // Fields
            if (widget.isSplitView)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _buildFields(editable),
                ),
              )
            else
              _buildFields(editable),

            // Sticky Bottom Action Bar
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: AppColors.borderFor(context)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                SecondaryButton(
                  label: 'New Category',
                  icon: Icons.add_rounded,
                  onPressed: () => ref.read(categoryBrowserProvider.notifier).startNew(),
                ),
                const Spacer(),
                if (!browser.isNew) ...[
                  SecondaryButton(
                    label: browser.isEditing ? 'Cancel / Lock' : 'Modify',
                    icon: browser.isEditing ? Icons.lock_outline_rounded : Icons.edit_outlined,
                    onPressed: () {
                      if (browser.isEditing) {
                        _populate(browser.current?.name, browser.current?.description);
                      }
                      ref.read(categoryBrowserProvider.notifier).toggleEditing();
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                PrimaryButton(
                  label: browser.isSaving ? 'Saving…' : (browser.isNew ? 'Create Category' : 'Save Changes'),
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: editable && !browser.isSaving ? _save : null,
                ),
              ],
            ),
          ],
        );

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: widget.isSplitView ? SizedBox(height: double.infinity, child: cardContent) : cardContent,
        );
      },
    );
  }

  Widget _buildFields(bool editable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'CATEGORY NAME *',
          controller: _name,
          enabled: editable,
          hint: 'e.g. Single Malt Scotch Whisky',
          selectAllOnFocus: true,
          showPasteButton: true,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'DESCRIPTION & NOTES',
          controller: _description,
          enabled: editable,
          hint: 'Sub-classification, tax notes, or display group details…',
        ),
      ],
    );
  }
}
