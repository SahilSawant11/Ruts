import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/masters_providers.dart';
import '../packaging_browser_controller.dart';

class PackagingsTable extends ConsumerStatefulWidget {
  const PackagingsTable({super.key});

  @override
  ConsumerState<PackagingsTable> createState() => _PackagingsTableState();
}

class _PackagingsTableState extends ConsumerState<PackagingsTable> {
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
    final packingsAsync = ref.watch(packingsListProvider);
    final browser = ref.watch(packagingBrowserProvider);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'All Packaging',
                  subtitle: 'Tap a row to load it below',
                ),
              ),
              SizedBox(
                width: 240,
                child: AppTextField(
                  label: '',
                  hint: 'Search packaging',
                  controller: _search,
                  suffix: const Icon(Icons.search_rounded, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          packingsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: Text('Could not load packaging: $error', style: AppTypography.bodyMuted)),
            ),
            data: (packings) {
              final query = _search.text.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? packings
                  : packings.where((p) {
                      return p.name.toLowerCase().contains(query) ||
                          (p.description ?? '').toLowerCase().contains(query);
                    }).toList();

              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: Text('No packaging matches "$query".', style: AppTypography.bodyMuted)),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _headerRow(),
                      Divider(height: 1, color: AppColors.borderFor(context)),
                      for (final packing in filtered)
                        _dataRow(
                          packing.name,
                          packing.description ?? '—',
                          browser.current?.name == packing.name,
                        ),
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
          _cell('NAME', flex: 2, header: true),
          _cell('DESCRIPTION', flex: 5, header: true),
        ],
      ),
    );
  }

  Widget _dataRow(String name, String description, bool isSelected) {
    final selectedBg = AppColors.isDark(context)
        ? AppColors.primary.withValues(alpha: 0.16)
        : AppColors.primarySoft;
    return InkWell(
      onTap: () => ref.read(packagingBrowserProvider.notifier).selectByName(name),
      child: Container(
        color: isSelected ? selectedBg : null,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            _cell(name, flex: 2, bold: true),
            _cell(description, flex: 5, muted: description == '—'),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, {required int flex, bool header = false, bool bold = false, bool muted = false}) {
    final style = header
        ? AppTypography.label.copyWith(color: AppColors.textMutedFor(context))
        : AppTypography.body.copyWith(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: muted ? AppColors.textMutedFor(context) : AppColors.textPrimaryFor(context),
          );
    return Expanded(
      flex: flex,
      child: Text(text, overflow: TextOverflow.ellipsis, style: style),
    );
  }
}
