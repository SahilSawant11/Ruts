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
import '../../data/master_import_service.dart';
import '../../data/masters_providers.dart';
import '../../data/models/supplier_dto.dart';
import '../supplier_browser_controller.dart';

enum _SupplierSortField { name, balance, vat }

class SuppliersTable extends ConsumerStatefulWidget {
  const SuppliersTable({super.key, this.isSplitView = false});

  final bool isSplitView;

  @override
  ConsumerState<SuppliersTable> createState() => _SuppliersTableState();
}

class _SuppliersTableState extends ConsumerState<SuppliersTable> {
  final _search = TextEditingController();
  bool _isImporting = false;
  _SupplierSortField _sortField = _SupplierSortField.name;
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
      final summary = await ref.read(masterImportServiceProvider).pickAndImport(MasterImportTarget.suppliers);
      if (!mounted || summary == null) return;

      ref.invalidate(suppliersListProvider);

      final firstError = summary.errors.isEmpty ? null : summary.errors.first;
      final isError = summary.failed > 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(firstError == null ? summary.message : '${summary.message}\n$firstError'),
          backgroundColor: isError ? AppColors.danger : AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _toggleSort(_SupplierSortField field) {
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
    final suppliersAsync = ref.watch(suppliersListProvider);
    final browser = ref.watch(supplierBrowserProvider);
    final pendingSyncAsync = ref.watch(pendingMastersSyncCountProvider);

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                title: 'Suppliers Directory',
                subtitle: widget.isSplitView
                    ? 'Select a supplier to inspect details'
                    : 'Tap a row to load it below',
              ),
            ),
            suppliersAsync.maybeWhen(
              data: (suppliers) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: StatusChip(label: '${suppliers.length} vendors'),
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
              onPressed: () => ref.read(supplierBrowserProvider.notifier).startNew(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Search Input
        AppTextField(
          label: '',
          hint: 'Search by vendor name, contact phone, or VAT / GST number…',
          controller: _search,
          suffix: const Icon(Icons.search_rounded, size: 18),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Table Header
        _headerRow(context),
        Divider(height: 1, color: AppColors.borderFor(context)),

        // Table Body
        suppliersAsync.when(
          loading: () => const Expanded(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => Expanded(
            child: Center(
              child: Text(
                'Could not load suppliers: $error',
                style: AppTypography.bodyMuted.copyWith(color: AppColors.textSecondaryFor(context)),
              ),
            ),
          ),
          data: (suppliers) {
            final query = _search.text.trim().toLowerCase();
            var filtered = query.isEmpty
                ? suppliers
                : suppliers.where((s) {
                    return s.name.toLowerCase().contains(query) ||
                        (s.contactNo ?? '').toLowerCase().contains(query) ||
                        (s.email ?? '').toLowerCase().contains(query) ||
                        (s.vatNo ?? '').toLowerCase().contains(query);
                  }).toList();

            // Sorting
            filtered.sort((a, b) {
              int cmp;
              switch (_sortField) {
                case _SupplierSortField.name:
                  cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
                  break;
                case _SupplierSortField.balance:
                  cmp = a.openingBalance.compareTo(b.openingBalance);
                  break;
                case _SupplierSortField.vat:
                  cmp = (a.vatNo ?? '').compareTo(b.vatNo ?? '');
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
                      Text('No suppliers match "$query".', style: AppTypography.bodyMuted),
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
                final s = filtered[index];
                return _dataRow(s, isSelected: browser.current?.id == s.id && !browser.isNew);
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
            _sortableHeader('SUPPLIER / CONTACT', _SupplierSortField.name, flex: 6),
            _sortableHeader('VAT NO.', _SupplierSortField.vat, flex: 3),
            _sortableHeader('BALANCE (₹)', _SupplierSortField.balance, flex: 3, alignEnd: true),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          _sortableHeader('NAME', _SupplierSortField.name, flex: 3),
          _cell('CONTACT', flex: 2, header: true),
          _cell('EMAIL', flex: 3, header: true),
          _sortableHeader('VAT NO.', _SupplierSortField.vat, flex: 2),
          _sortableHeader('BALANCE', _SupplierSortField.balance, flex: 2, alignEnd: true),
          _cell('TYPE', flex: 1, header: true),
          _cell('SYNC', flex: 1, header: true),
        ],
      ),
    );
  }

  Widget _sortableHeader(String label, _SupplierSortField field, {required int flex, bool alignEnd = false}) {
    final isCurrent = _sortField == field;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _toggleSort(field),
        child: Row(
          mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: isCurrent ? AppColors.primary : AppColors.textMutedFor(context),
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
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

  Widget _dataRow(SupplierDto s, {required bool isSelected}) {
    final isDark = AppColors.isDark(context);
    final selectedBg = isDark
        ? AppColors.primary.withValues(alpha: 0.18)
        : AppColors.primary.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      child: InkWell(
        onTap: () => ref.read(supplierBrowserProvider.notifier).selectById(s.id),
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
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.name,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textPrimaryFor(context),
                            ),
                          ),
                        if ((s.contactNo ?? '').isNotEmpty)
                          Text(
                            s.contactNo!,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              color: AppColors.textMutedFor(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _cell(s.vatNo ?? '—', flex: 3, mono: true, selected: isSelected),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${s.openingBalance.toStringAsFixed(0)}',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.primary : AppColors.textPrimaryFor(context),
                          ),
                        ),
                        Text(
                          s.balanceType,
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: s.balanceType == 'Credit' ? AppColors.danger : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  _cell(s.name, flex: 3, bold: true, selected: isSelected),
                  _cell(s.contactNo ?? '—', flex: 2, selected: isSelected),
                  _cell(s.email ?? '—', flex: 3, selected: isSelected),
                  _cell(s.vatNo ?? '—', flex: 2, mono: true, selected: isSelected),
                  _cell(
                    '₹${s.openingBalance.toStringAsFixed(0)}',
                    flex: 2,
                    alignEnd: true,
                    selected: isSelected,
                  ),
                  Expanded(
                    flex: 1,
                    child: TagPill(
                      label: s.balanceType,
                      tone: s.balanceType == 'Credit' ? TagPillTone.danger : TagPillTone.success,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: s.isPendingSync
                        ? const TagPill(label: 'Pending', tone: TagPillTone.amber)
                        : const SizedBox.shrink(),
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
