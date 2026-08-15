import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/tag_pill.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../../sales/data/models/material_dto.dart';
import '../../data/masters_providers.dart';
import '../material_browser_controller.dart';

/// Full list of materials in a scrollable table. Tapping a row loads
/// that material into MaterialFormCard below for viewing/editing —
/// this is the "see everything at once" view; the form card is the
/// "work on one record" view.
class MaterialsTable extends ConsumerStatefulWidget {
  const MaterialsTable({super.key});

  @override
  ConsumerState<MaterialsTable> createState() => _MaterialsTableState();
}

class _MaterialsTableState extends ConsumerState<MaterialsTable> {
  final _search = TextEditingController();

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
    final materialsAsync = ref.watch(materialsListProvider);
    final browser = ref.watch(materialBrowserProvider);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(title: 'All Materials', subtitle: 'Tap a row to load it below'),
              ),
              SizedBox(
                width: 240,
                child: AppTextField(label: '', hint: 'Search name or code', controller: _search, suffix: const Icon(Icons.search_rounded, size: 18)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          materialsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: Text('Could not load materials: $error', style: AppTypography.bodyMuted)),
            ),
            data: (materials) {
              final query = _search.text.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? materials
                  : materials
                      .where((m) => m.name.toLowerCase().contains(query) || m.id.toLowerCase().contains(query))
                      .toList();

              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: Text('No materials match "$query".', style: AppTypography.bodyMuted)),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _headerRow(),
                      Divider(height: 1, color: AppColors.borderFor(context)),
                      for (final m in filtered) _dataRow(m, isSelected: browser.current?.id == m.id),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _cell('ITEM CODE', flex: 2, header: true),
          _cell('NAME', flex: 4, header: true),
          _cell('CATEGORY', flex: 1, header: true),
          _cell('PACKING', flex: 2, header: true),
          _cell('BARCODE', flex: 2, header: true),
          _cell('SYNC', flex: 1, header: true),
          _cell('SALE RATE', flex: 1, header: true, alignEnd: true),
        ],
      ),
    );
  }

  Widget _dataRow(MaterialDto m, {required bool isSelected}) {
    final selectedBg = AppColors.isDark(context)
        ? AppColors.primary.withValues(alpha: 0.16)
        : AppColors.primarySoft;

    return InkWell(
      onTap: () => ref.read(materialBrowserProvider.notifier).selectById(m.id),
      child: Container(
        color: isSelected ? selectedBg : null,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            _cell(m.id, flex: 2, mono: true, selected: isSelected),
            _cell(m.name, flex: 4, bold: true, selected: isSelected),
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
        color: AppColors.textPrimaryFor(context),
      );
    }
    return Expanded(
      flex: flex,
      child: Text(text, textAlign: alignEnd ? TextAlign.end : TextAlign.start, overflow: TextOverflow.ellipsis, style: style),
    );
  }
}
