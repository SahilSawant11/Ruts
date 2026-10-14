import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/masters_providers.dart';
import '../../data/models/category_dto.dart';
import '../category_browser_controller.dart';

class CategoriesTable extends ConsumerStatefulWidget {
  const CategoriesTable({super.key, this.isSplitView = false});

  final bool isSplitView;

  @override
  ConsumerState<CategoriesTable> createState() => _CategoriesTableState();
}

class _CategoriesTableState extends ConsumerState<CategoriesTable> {
  final _search = TextEditingController();
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    final browser = ref.watch(categoryBrowserProvider);

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                title: 'Categories Directory',
                subtitle: widget.isSplitView
                    ? 'Select a category to view & edit'
                    : 'Tap a row to load it below',
              ),
            ),
            categoriesAsync.maybeWhen(
              data: (categories) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: StatusChip(label: '${categories.length} categories'),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            SecondaryButton(
              label: 'New',
              icon: Icons.add_rounded,
              dense: true,
              onPressed: () => ref.read(categoryBrowserProvider.notifier).startNew(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Search Input
        AppTextField(
          label: '',
          hint: 'Search category name or description…',
          controller: _search,
          suffix: const Icon(Icons.search_rounded, size: 18),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Table Header
        _headerRow(context),
        Divider(height: 1, color: AppColors.borderFor(context)),

        // Table Body
        categoriesAsync.when(
          loading: () => const Expanded(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => Expanded(
            child: Center(
              child: Text('Could not load categories: $error', style: AppTypography.bodyMuted),
            ),
          ),
          data: (categories) {
            // Keep browser synchronized
            if (categories.isNotEmpty &&
                (browser.categories.isEmpty || browser.categories.length != categories.length)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ref.read(categoryBrowserProvider.notifier).syncList(categories);
              });
            }

            final query = _search.text.trim().toLowerCase();
            var filtered = query.isEmpty
                ? categories
                : categories.where((category) {
                    return category.name.toLowerCase().contains(query) ||
                        (category.description ?? '').toLowerCase().contains(query);
                  }).toList();

            filtered.sort((a, b) {
              final cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
              return _sortAscending ? cmp : -cmp;
            });

            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded, size: 36, color: AppColors.textMutedFor(context)),
                      const SizedBox(height: 8),
                      Text('No categories match "$query".', style: AppTypography.bodyMuted),
                    ],
                  ),
                ),
              );
            }

            final listWidget = ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final category = filtered[index];
                final isSelected = browser.current?.name == category.name && !browser.isNew;
                return _dataRow(
                  category,
                  categories,
                  isSelected: isSelected,
                );
              },
            );

            if (widget.isSplitView) {
              return Expanded(child: listWidget);
            } else {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: listWidget,
              );
            }
          },
        ),
      ],
    );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: widget.isSplitView ? SizedBox(height: double.infinity, child: cardContent) : cardContent,
    );
  }

  Widget _headerRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => setState(() => _sortAscending = !_sortAscending),
              child: Row(
                children: [
                  Text(
                    'CATEGORY NAME',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textMutedFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 13,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          _cell('DESCRIPTION', flex: 5, header: true),
        ],
      ),
    );
  }

  Widget _dataRow(
    CategoryDto category,
    List<CategoryDto> allCategories, {
    required bool isSelected,
  }) {
    final isDark = AppColors.isDark(context);
    final selectedBg = isDark
        ? AppColors.primary.withValues(alpha: 0.18)
        : AppColors.primary.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: InkWell(
        onTap: () => ref.read(categoryBrowserProvider.notifier).selectByName(category.name, allCategories),
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.22),
                    width: 1,
                  )
                : null,
          ),
          padding: EdgeInsets.symmetric(
            vertical: widget.isSplitView ? 9 : 10,
            horizontal: 10,
          ),
          child: Row(
            children: [
              _cell(
                category.name,
                flex: 3,
                bold: isSelected,
                selected: isSelected,
              ),
              _cell(
                category.description ?? '—',
                flex: 5,
                muted: (category.description ?? '').isEmpty,
                selected: isSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(
    String text, {
    required int flex,
    bool header = false,
    bool bold = false,
    bool muted = false,
    bool selected = false,
  }) {
    TextStyle style;
    if (header) {
      style = AppTypography.label.copyWith(color: AppColors.textMutedFor(context));
    } else {
      style = AppTypography.body.copyWith(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: selected
            ? AppColors.textPrimaryFor(context)
            : muted
                ? AppColors.textMutedFor(context)
                : AppColors.textPrimaryFor(context),
      );
    }
    return Expanded(
      flex: flex,
      child: Text(text, overflow: TextOverflow.ellipsis, style: style),
    );
  }
}
