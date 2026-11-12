import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../data/local_masters_repository.dart';
import '../../data/masters_providers.dart';

/// Row selection for a masters table. Select-all acts on the rows currently
/// visible (after search and filters), like a spreadsheet.
mixin BulkSelection<T extends StatefulWidget> on State<T> {
  final Set<String> selectedIds = {};

  void toggleSelected(String id) => setState(() {
        if (!selectedIds.remove(id)) selectedIds.add(id);
      });

  /// true = all visible selected, false = none, null = some (dash).
  bool? selectAllState(Iterable<String> visibleIds) {
    final n = visibleIds.where(selectedIds.contains).length;
    if (n == 0) return false;
    return n == visibleIds.length ? true : null;
  }

  void toggleSelectAll(Iterable<String> visibleIds) => setState(() {
        if (selectAllState(visibleIds) == true) {
          selectedIds.removeAll(visibleIds);
        } else {
          selectedIds.addAll(visibleIds);
        }
      });

  void clearSelection() => setState(selectedIds.clear);

  bool bulkDeleting = false;

  /// Runs [confirmBulkDelete] for the current selection. Deleted rows leave
  /// the selection; rows kept because they are in use stay selected.
  Future<void> deleteSelected({
    required WidgetRef ref,
    required MasterKind kind,
    required String singular,
    required String plural,
    required ProviderOrFamily listProvider,
  }) async {
    setState(() => bulkDeleting = true);
    final r = await confirmBulkDelete(
      context: context,
      ref: ref,
      kind: kind,
      ids: {...selectedIds},
      singular: singular,
      plural: plural,
      listProvider: listProvider,
    );
    if (!mounted) return;
    setState(() {
      bulkDeleting = false;
      if (r != null) selectedIds.removeAll(r.deleted);
    });
  }
}

/// Compact checkbox used in the header (tristate) and in each row.
class SelectBox extends StatelessWidget {
  const SelectBox({super.key, required this.value, required this.onChanged});

  final bool? value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Checkbox(
          value: value,
          tristate: true,
          onChanged: (_) => onChanged(),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeColor: AppColors.primary,
          side: BorderSide(color: AppColors.textMutedFor(context), width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}

/// Replaces a table's toolbar while rows are selected.
class BulkActionBar extends StatelessWidget {
  const BulkActionBar({
    super.key,
    required this.count,
    required this.onClear,
    required this.onDelete,
    this.busy = false,
  });

  final int count;
  final VoidCallback onClear;
  final VoidCallback onDelete;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Text('$count selected', style: AppTypography.sectionTitleFor(context)),
          const SizedBox(width: AppSpacing.sm),
          TextButton(onPressed: busy ? null : onClear, child: const Text('Clear')),
          const Spacer(),
          DangerButton(
            label: busy ? 'Deleting…' : 'Delete $count',
            icon: AppIcons.delete,
            outline: true,
            onPressed: busy ? null : onDelete,
          ),
        ],
      ),
    );
  }
}

/// Confirms, deletes what is safe to delete, and reports what was kept.
/// Returns the result, or null if the user cancelled or it failed.
Future<BulkDeleteResult?> confirmBulkDelete({
  required BuildContext context,
  required WidgetRef ref,
  required MasterKind kind,
  required Set<String> ids,
  required String singular,
  required String plural,
  required ProviderOrFamily listProvider,
}) async {
  final n = ids.length;
  final noun = n == 1 ? singular : plural;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete $n $noun?'),
      content: Text(
        'This can\'t be undone. Any ${plural.toLowerCase()} still used on bills, in stock or by products '
        'are kept and listed afterwards.',
      ),
      actions: [
        SecondaryButton(label: 'Cancel', onPressed: () => Navigator.of(ctx).pop(false)),
        DangerButton(label: 'Delete', onPressed: () => Navigator.of(ctx).pop(true)),
      ],
    ),
  );
  if (ok != true) return null;

  try {
    final r = await ref.read(mastersRepositoryProvider).deleteMasters(kind, ids);
    ref.invalidate(listProvider);
    AppLogger.info('Masters', 'Bulk delete $kind: ${r.deleted.length} deleted, ${r.kept.length} kept');
    if (!context.mounted) return r;

    final parts = <String>[];
    if (r.deleted.isNotEmpty) {
      parts.add('Deleted ${r.deleted.length} ${r.deleted.length == 1 ? singular : plural}.');
    }
    if (r.kept.isNotEmpty) {
      final shown = r.kept.entries.take(3).map((e) => '${e.key} (${e.value})').join(', ');
      final more = r.kept.length > 3 ? ' and ${r.kept.length - 3} more' : '';
      parts.add('Kept ${r.kept.length} still in use: $shown$more.');
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(parts.join(' '), style: const TextStyle(color: Colors.white)),
      backgroundColor: r.deleted.isEmpty ? AppColors.warning : AppColors.success,
      duration: Duration(seconds: r.kept.isEmpty ? 3 : 7),
    ));
    return r;
  } catch (e, st) {
    AppLogger.error('Masters', e, st);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not delete: $e', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.danger,
      ));
    }
    return null;
  }
}
