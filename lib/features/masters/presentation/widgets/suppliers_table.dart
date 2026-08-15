import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/tag_pill.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/masters_providers.dart';
import '../../data/models/supplier_dto.dart';
import '../supplier_browser_controller.dart';

class SuppliersTable extends ConsumerStatefulWidget {
  const SuppliersTable({super.key});

  @override
  ConsumerState<SuppliersTable> createState() => _SuppliersTableState();
}

class _SuppliersTableState extends ConsumerState<SuppliersTable> {
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
    final suppliersAsync = ref.watch(suppliersListProvider);
    final browser = ref.watch(supplierBrowserProvider);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'All Suppliers',
                  subtitle: 'Tap a row to load it below',
                ),
              ),
              SizedBox(
                width: 240,
                child: AppTextField(
                  label: '',
                  hint: 'Search supplier or contact',
                  controller: _search,
                  suffix: const Icon(Icons.search_rounded, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          suppliersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'Could not load suppliers: $error',
                  style: AppTypography.bodyMuted.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
          ),
            data: (suppliers) {
              if ((browser.suppliers.isEmpty && suppliers.isNotEmpty) ||
                  browser.suppliers.length != suppliers.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  ref.read(supplierBrowserProvider.notifier).syncList(suppliers);
                });
              }

              final query = _search.text.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? suppliers
                  : suppliers.where((s) {
                      return s.name.toLowerCase().contains(query) ||
                          (s.contactNo ?? '').toLowerCase().contains(query) ||
                          (s.email ?? '').toLowerCase().contains(query);
                    }).toList();

              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'No suppliers match "$query".',
                      style: AppTypography.bodyMuted.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _headerRow(),
                      Divider(height: 1, color: AppColors.borderFor(context)),
                      for (final supplier in filtered)
                        _dataRow(
                          supplier,
                          isSelected: browser.current?.id == supplier.id,
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
          _cell('NAME', flex: 4, header: true),
          _cell('CONTACT', flex: 2, header: true),
          _cell('EMAIL', flex: 3, header: true),
          _cell('DISC %', flex: 1, header: true, alignEnd: true),
          _cell('BALANCE', flex: 2, header: true, alignEnd: true),
          _cell('SYNC', flex: 1, header: true),
        ],
      ),
    );
  }

  Widget _dataRow(SupplierDto supplier, {required bool isSelected}) {
    final selectedBg = AppColors.isDark(context)
        ? AppColors.primary.withValues(alpha: 0.16)
        : AppColors.primarySoft;

    return InkWell(
      onTap: () => ref.read(supplierBrowserProvider.notifier).selectById(supplier.id),
      child: Container(
        color: isSelected ? selectedBg : null,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            _cell(supplier.name, flex: 4, bold: true, selected: isSelected),
            _cell(
              supplier.contactNo ?? '—',
              flex: 2,
              mono: true,
              muted: supplier.contactNo == null,
              selected: isSelected,
            ),
            _cell(
              supplier.email ?? '—',
              flex: 3,
              muted: supplier.email == null,
              selected: isSelected,
            ),
            _cell(
              supplier.disPercent == 0 ? '—' : supplier.disPercent.toStringAsFixed(0),
              flex: 1,
              alignEnd: true,
              selected: isSelected,
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: TagPill(
                  label: '${supplier.balanceType} ₹${supplier.openingBalance.toStringAsFixed(0)}',
                  tone: supplier.balanceType == 'Debit'
                      ? TagPillTone.amber
                      : TagPillTone.neutral,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: supplier.isPendingSync
                  ? const TagPill(label: 'Pending', tone: TagPillTone.amber)
                  : const SizedBox.shrink(),
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
        color: selected
            ? AppColors.textPrimaryFor(context)
            : muted
                ? AppColors.textMutedFor(context)
                : AppColors.textPrimaryFor(context),
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
