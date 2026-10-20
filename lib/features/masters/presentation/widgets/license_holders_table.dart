import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/master_import_service.dart';
import '../../data/masters_providers.dart';
import '../../data/models/license_holder_dto.dart';
import '../license_holder_browser_controller.dart';

enum _LicenseSortField { permitNo, name, issuedDate }

class LicenseHoldersTable extends ConsumerStatefulWidget {
  const LicenseHoldersTable({super.key, this.isSplitView = false});

  final bool isSplitView;

  @override
  ConsumerState<LicenseHoldersTable> createState() => _LicenseHoldersTableState();
}

class _LicenseHoldersTableState extends ConsumerState<LicenseHoldersTable> {
  final _search = TextEditingController();
  _LicenseSortField _sortField = _LicenseSortField.permitNo;
  bool _sortAscending = true;
  bool _isImporting = false;

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
      final summary = await ref
          .read(masterImportServiceProvider)
          .pickAndImport(MasterImportTarget.licenseHolders);
      if (!mounted || summary == null) return;

      ref.invalidate(licenseHoldersListProvider);

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

  void _toggleSort(_LicenseSortField field) {
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
    final holdersAsync = ref.watch(licenseHoldersListProvider);
    final browser = ref.watch(licenseHolderBrowserProvider);

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                title: 'License Holders Directory',
                subtitle: widget.isSplitView
                    ? 'Permit holders for excise retail sales'
                    : 'Tap a row to view or edit below',
              ),
            ),
            holdersAsync.maybeWhen(
              data: (holders) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: StatusChip(label: '${holders.length} permits'),
              ),
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
              onPressed: () => ref.read(licenseHolderBrowserProvider.notifier).startNew(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Search Input
        AppTextField(
          label: '',
          hint: 'Search by permit no, holder name, or location…',
          controller: _search,
          suffix: const Icon(Icons.search_rounded, size: 18),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Table Header
        _headerRow(context),
        Divider(height: 1, color: AppColors.borderFor(context)),

        // Table Body
        holdersAsync.when(
          loading: () => const Expanded(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => Expanded(
            child: Center(
              child: Text('Could not load license holders: $error', style: AppTypography.bodyMuted),
            ),
          ),
          data: (holders) {
            if (holders.isNotEmpty &&
                (browser.licenseHolders.isEmpty ||
                    browser.licenseHolders.length != holders.length)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ref.read(licenseHolderBrowserProvider.notifier).syncList(holders);
                }
              });
            }

            final query = _search.text.trim().toLowerCase();
            final filtered = holders.where((h) {
              if (query.isEmpty) return true;
              return h.permitNo.toLowerCase().contains(query) ||
                  h.name.toLowerCase().contains(query) ||
                  (h.whereGranted?.toLowerCase().contains(query) ?? false) ||
                  (h.issuedDate?.toLowerCase().contains(query) ?? false);
            }).toList();

            filtered.sort((a, b) {
              final cmp = switch (_sortField) {
                _LicenseSortField.permitNo => a.permitNo.compareTo(b.permitNo),
                _LicenseSortField.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                _LicenseSortField.issuedDate =>
                  (a.issuedDate ?? '').compareTo(b.issuedDate ?? ''),
              };
              return _sortAscending ? cmp : -cmp;
            });

            if (filtered.isEmpty) {
              return Expanded(
                child: Center(
                  child: Text(
                    query.isEmpty ? 'No license holders found.' : 'No matches for "$query".',
                    style: AppTypography.bodyMuted,
                  ),
                ),
              );
            }

            return Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AppColors.borderFor(context)),
                itemBuilder: (context, index) {
                  final holder = filtered[index];
                  final isSelected = browser.current?.id == holder.id;

                  return InkWell(
                    onTap: () {
                      ref
                          .read(licenseHolderBrowserProvider.notifier)
                          .selectById(holder.id, holders);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 10,
                      ),
                      color: isSelected
                          ? AppColors.primarySoftFor(context)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              holder.permitNo,
                              style: AppTypography.mono.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryFor(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: Text(
                              holder.name,
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryFor(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              holder.issuedDate ?? '—',
                              style: AppTypography.bodyMutedFor(context).copyWith(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAltFor(context),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                holder.whereGranted ?? 'Life Time',
                                style: AppTypography.captionFor(context).copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16),
                              color: AppColors.textMutedFor(context),
                              tooltip: 'Delete permit',
                              onPressed: () => _confirmDelete(holder),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );

    if (widget.isSplitView) {
      return AppCard(child: cardContent);
    }

    return AppCard(
      child: SizedBox(
        height: 480,
        child: cardContent,
      ),
    );
  }

  Widget _headerRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      color: AppColors.surfaceAltFor(context),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _sortableColumn('Permit No.', _LicenseSortField.permitNo),
          ),
          Expanded(
            flex: 5,
            child: _sortableColumn('Permit Holder Name', _LicenseSortField.name),
          ),
          Expanded(
            flex: 3,
            child: _sortableColumn('Issued Date', _LicenseSortField.issuedDate),
          ),
          Expanded(
            flex: 3,
            child: Text('Where Granted', style: AppTypography.captionFor(context)),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _sortableColumn(String label, _LicenseSortField field) {
    final active = _sortField == field;
    return InkWell(
      onTap: () => _toggleSort(field),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTypography.captionFor(context).copyWith(
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active
                    ? AppColors.primary
                    : AppColors.textMutedFor(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (active) ...[
            const SizedBox(width: 2),
            Icon(
              _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 12,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(LicenseHolderDto holder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete License Holder'),
        content: Text('Are you sure you want to delete permit "${holder.permitNo} (${holder.name})"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(mastersRepositoryProvider).deleteLicenseHolder(holder.id);
      ref.invalidate(licenseHoldersListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('License holder deleted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}
