import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../../../shared/widgets/badges/tag_pill.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../../sales/data/models/material_dto.dart';
import '../../data/master_import_service.dart';
import '../../data/masters_providers.dart';
import '../material_browser_controller.dart';

enum _SortField { name, id, saleRate }

/// Full list of materials in a high-density, scrollable data table.
/// In split-view mode, rows are optimized for side-by-side inspection
/// with quick category pills and pinned headers.
class MaterialsTable extends ConsumerStatefulWidget {
  const MaterialsTable({super.key, this.isSplitView = false});

  final bool isSplitView;

  @override
  ConsumerState<MaterialsTable> createState() => _MaterialsTableState();
}

class _MaterialsTableState extends ConsumerState<MaterialsTable> {
  final _search = TextEditingController();
  bool _isImporting = false;
  String _selectedCategory = 'All';
  _SortField _sortField = _SortField.name;
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

  Future<void> _import() async {
    setState(() => _isImporting = true);
    try {
      final summary = await ref.read(masterImportServiceProvider).pickAndImport(MasterImportTarget.materials);
      if (!mounted || summary == null) return;

      ref.invalidate(materialsListProvider);

      final firstError = summary.errors.isEmpty ? null : summary.errors.first;
      final isError = summary.failed > 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firstError == null ? summary.message : '${summary.message}\n$firstError',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: isError ? AppColors.danger : AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _toggleSort(_SortField field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialsListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final browser = ref.watch(materialBrowserProvider);
    final pendingSyncAsync = ref.watch(pendingMastersSyncCountProvider);

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                title: 'Materials Directory',
                subtitle: widget.isSplitView
                    ? 'Select an item to inspect & modify'
                    : 'Tap a row to load it below',
              ),
            ),
            materialsAsync.maybeWhen(
              data: (materials) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: StatusChip(label: '${materials.length} SCM codes'),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            pendingSyncAsync.maybeWhen(
              data: (count) => count > 0
                  ? Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: StatusChip(label: '$count pending sync', tone: StatusChipTone.neutral),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
            SecondaryButton(
              label: _isImporting ? 'Importing…' : 'Import Excel',
              icon: Icons.upload_file_rounded,
              dense: true,
              onPressed: _isImporting ? null : _import,
            ),
            const SizedBox(width: AppSpacing.xs),
            SecondaryButton(
              label: 'New',
              icon: Icons.add_rounded,
              dense: true,
              onPressed: () => ref.read(materialBrowserProvider.notifier).startNew(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Search + Quick Filter Chips Row
        Row(
          children: [
            Expanded(
              flex: widget.isSplitView ? 5 : 4,
              child: AppTextField(
                label: '',
                hint: 'Search name, SCM code, brand…',
                controller: _search,
                suffix: const Icon(Icons.search_rounded, size: 18),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Category filter chips
            Expanded(
              flex: widget.isSplitView ? 6 : 6,
              child: categoriesAsync.maybeWhen(
                data: (categories) {
                  final allCategories = ['All', ...categories.map((c) => c.name)];
                  return SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: allCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, idx) {
                        final cat = allCategories[idx];
                        final isSelected = _selectedCategory == cat;
                        return InkWell(
                          onTap: () => setState(() => _selectedCategory = cat),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceAltFor(context),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.borderFor(context),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: AppTypography.caption.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimaryFor(context),
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Table Header
        _headerRow(context),
        Divider(height: 1, color: AppColors.borderFor(context)),

        // Table Body
        materialsAsync.when(
          loading: () => const Expanded(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => Expanded(
            child: Center(
              child: Text('Could not load materials: $error', style: AppTypography.bodyMuted),
            ),
          ),
          data: (materials) {
            if (materials.isNotEmpty &&
                (browser.materials.isEmpty || browser.materials.length != materials.length)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ref.read(materialBrowserProvider.notifier).syncList(materials);
              });
            }

            final query = _search.text.trim().toLowerCase();
            var filtered = materials.where((m) {
              final matchesQuery = query.isEmpty ||
                  m.name.toLowerCase().contains(query) ||
                  m.id.toLowerCase().contains(query) ||
                  m.manufacturer.toLowerCase().contains(query) ||
                  m.barcode.toLowerCase().contains(query);

              final matchesCategory =
                  _selectedCategory == 'All' || m.category.toLowerCase() == _selectedCategory.toLowerCase();

              return matchesQuery && matchesCategory;
            }).toList();

            // Sorting
            filtered.sort((a, b) {
              int cmp;
              switch (_sortField) {
                case _SortField.name:
                  cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
                  break;
                case _SortField.id:
                  cmp = a.id.toLowerCase().compareTo(b.id.toLowerCase());
                  break;
                case _SortField.saleRate:
                  cmp = a.saleRate.compareTo(b.saleRate);
                  break;
              }
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
                      Text(
                        'No materials found matching your filters.',
                        style: AppTypography.bodyMuted.copyWith(color: AppColors.textMutedFor(context)),
                      ),
                    ],
                  ),
                ),
              );
            }

            final listWidget = ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.borderFor(context).withValues(alpha: 0.4),
              ),
              itemBuilder: (context, index) {
                final m = filtered[index];
                final isSelected = browser.current != null &&
                    browser.current!.id.trim().toLowerCase() == m.id.trim().toLowerCase() &&
                    !browser.isNew;
                return _dataRow(
                  m,
                  materials,
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
    if (widget.isSplitView) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            _sortableHeader('SCM CODE', _SortField.id, flex: 3),
            _sortableHeader('NAME & BRAND', _SortField.name, flex: 6),
            _cell('PACKING', flex: 3, header: true),
            _cell('STATUS', flex: 2, header: true),
            _sortableHeader('RATE (₹)', _SortField.saleRate, flex: 2, alignEnd: true),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          _sortableHeader('SCM CODE', _SortField.id, flex: 2),
          _sortableHeader('NAME', _SortField.name, flex: 4),
          _cell('MANUFACTURER', flex: 2, header: true),
          _cell('CATEGORY', flex: 1, header: true),
          _cell('PACKING', flex: 2, header: true),
          _cell('BARCODE', flex: 2, header: true),
          _cell('STATUS', flex: 1, header: true),
          _cell('SYNC', flex: 1, header: true),
          _sortableHeader('SALE RATE', _SortField.saleRate, flex: 1, alignEnd: true),
        ],
      ),
    );
  }

  Widget _sortableHeader(String label, _SortField field, {required int flex, bool alignEnd = false}) {
    final isCurrent = _sortField == field;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _toggleSort(field),
        child: Row(
          mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                label,
                style: AppTypography.label.copyWith(
                  color: isCurrent ? AppColors.primary : AppColors.textMutedFor(context),
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 3),
              Icon(
                _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 13,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dataRow(MaterialDto m, List<MaterialDto> allMaterials, {required bool isSelected}) {
    final isDark = AppColors.isDark(context);
    final selectedBg = isDark
        ? AppColors.primary.withValues(alpha: 0.18)
        : AppColors.primary.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      child: InkWell(
        onTap: () => ref.read(materialBrowserProvider.notifier).selectById(m.id, allMaterials),
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
            vertical: widget.isSplitView ? 8 : 9,
            horizontal: 10,
          ),
          child: widget.isSplitView
              ? Row(
                  children: [
                    _cell(m.id, flex: 3, mono: true, selected: isSelected),
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            m.name,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textPrimaryFor(context),
                            ),
                          ),
                        if (m.manufacturer.isNotEmpty)
                          Text(
                            m.manufacturer,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              color: AppColors.textMutedFor(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            m.packing,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryFor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: m.isActive
                        ? const TagPill(label: 'Active', tone: TagPillTone.success)
                        : const TagPill(label: 'Inactive', tone: TagPillTone.neutral),
                  ),
                  _cell(
                    m.saleRate == 0 ? '—' : '₹${m.saleRate.toStringAsFixed(0)}',
                    flex: 2,
                    alignEnd: true,
                    bold: true,
                    selected: isSelected,
                  ),
                ],
              )
            : Row(
                children: [
                  _cell(m.id, flex: 2, mono: true, selected: isSelected),
                  _cell(m.name, flex: 4, bold: true, selected: isSelected),
                  _cell(m.manufacturer, flex: 2, selected: isSelected),
                  Expanded(flex: 1, child: TagPill(label: m.category, tone: TagPillTone.neutral)),
                  _cell(m.packing, flex: 2, selected: isSelected),
                  _cell(
                    m.barcode,
                    flex: 2,
                    mono: true,
                    muted: m.barcode == m.id,
                    selected: isSelected,
                  ),
                  Expanded(
                    flex: 1,
                    child: m.isActive
                        ? const TagPill(label: 'Active', tone: TagPillTone.success)
                        : const TagPill(label: 'Inactive', tone: TagPillTone.neutral),
                  ),
                  Expanded(
                    flex: 1,
                    child: m.isPendingSync
                        ? const TagPill(label: 'Pending', tone: TagPillTone.amber)
                        : const SizedBox.shrink(),
                  ),
                  _cell(
                    m.saleRate == 0 ? '—' : '₹${m.saleRate.toStringAsFixed(0)}',
                    flex: 1,
                    alignEnd: true,
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
    bool alignEnd = false,
    bool bold = false,
    bool mono = false,
    bool muted = false,
    bool selected = false,
  }) {
    TextStyle style;
    if (header) {
      style = AppTypography.label.copyWith(
        color: AppColors.textMutedFor(context),
      );
    } else if (mono) {
      style = AppTypography.mono.copyWith(
        fontSize: 12,
        color: selected
            ? AppColors.textPrimaryFor(context)
            : muted
                ? AppColors.textMutedFor(context)
                : AppColors.textSecondaryFor(context),
      );
    } else {
      style = AppTypography.body.copyWith(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppColors.primary : AppColors.textPrimaryFor(context),
      );
    }
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
