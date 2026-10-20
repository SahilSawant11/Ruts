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
import '../../data/models/packaging_dto.dart';
import '../packaging_browser_controller.dart';

class PackagingsTable extends ConsumerStatefulWidget {
  const PackagingsTable({super.key, this.isSplitView = false});

  final bool isSplitView;

  @override
  ConsumerState<PackagingsTable> createState() => _PackagingsTableState();
}

class _PackagingsTableState extends ConsumerState<PackagingsTable> {
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
    final packingsAsync = ref.watch(packingsListProvider);
    final browser = ref.watch(packagingBrowserProvider);

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                title: 'Packaging Directory',
                subtitle: widget.isSplitView
                    ? 'Select a volume or packaging size to inspect'
                    : 'Tap a row to load it below',
              ),
            ),
            packingsAsync.maybeWhen(
              data: (packings) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: StatusChip(label: '${packings.length} sizes'),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            SecondaryButton(
              label: 'New',
              icon: Icons.add_rounded,
              dense: true,
              onPressed: () => ref.read(packagingBrowserProvider.notifier).startNew(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Search Input
        AppTextField(
          label: '',
          hint: 'Search packaging size (e.g. 750 ML, Pint, Can)…',
          controller: _search,
          suffix: const Icon(Icons.search_rounded, size: 18),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Table Header
        _headerRow(context),
        Divider(height: 1, color: AppColors.borderFor(context)),

        // Table Body
        packingsAsync.when(
          loading: () => const Expanded(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => Expanded(
            child: Center(
              child: Text('Could not load packaging: $error', style: AppTypography.bodyMuted),
            ),
          ),
          data: (packings) {
            if (packings.isNotEmpty &&
                (browser.packings.isEmpty || browser.packings.length != packings.length)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ref.read(packagingBrowserProvider.notifier).syncList(packings);
              });
            }

            final query = _search.text.trim().toLowerCase();
            var filtered = query.isEmpty
                ? packings
                : packings.where((p) {
                    return p.name.toLowerCase().contains(query) ||
                        (p.description ?? '').toLowerCase().contains(query);
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
                      Text('No packaging matches "$query".', style: AppTypography.bodyMuted),
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
                final p = filtered[index];
                final isSelected = browser.current != null &&
                    browser.current!.name.trim().toLowerCase() == p.name.trim().toLowerCase() &&
                    !browser.isNew;
                return _dataRow(
                  p.name,
                  p.description ?? '—',
                  packings,
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => setState(() => _sortAscending = !_sortAscending),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'PACKAGING / SIZE',
                      style: AppTypography.label.copyWith(
                        color: AppColors.textMutedFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          _cell('DESCRIPTION / SPECIFICATION', flex: 5, header: true),
        ],
      ),
    );
  }

  Widget _dataRow(String name, String description, List<PackagingDto> allPackings, {required bool isSelected}) {
    final isDark = AppColors.isDark(context);
    final selectedBg = isDark
        ? AppColors.primary.withValues(alpha: 0.18)
        : AppColors.primary.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: InkWell(
        onTap: () => ref.read(packagingBrowserProvider.notifier).selectByName(name, allPackings),
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
              _cell(name, flex: 3, bold: isSelected, selected: isSelected),
              _cell(
                description,
                flex: 5,
                muted: description == '—',
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
            ? AppColors.primary
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
