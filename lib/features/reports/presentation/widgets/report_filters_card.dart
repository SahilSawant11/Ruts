import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/reports_providers.dart';

/// From/To date range picker + Generate button. Picking dates only
/// updates local pending state — Generate is what actually commits
/// the new range to reportDateRangeProvider (and triggers the fetch),
/// so the report doesn't refire on every single date tap.
class ReportFiltersCard extends ConsumerStatefulWidget {
  const ReportFiltersCard({super.key});

  @override
  ConsumerState<ReportFiltersCard> createState() => _ReportFiltersCardState();
}

class _ReportFiltersCardState extends ConsumerState<ReportFiltersCard> {
  DateTime? _from;
  DateTime? _to;
  DateTimeRange? _lastSyncedRange;

  String _fmt(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')}-${months[d.month - 1]}-${d.year}';
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  void _generate() {
    if (_from == null || _to == null) return;
    final from = _from!.isAfter(_to!) ? _to! : _from!;
    final to = _from!.isAfter(_to!) ? _from! : _to!;
    ref.read(reportDateRangeProvider.notifier).state = DateTimeRange(start: from, end: to);
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(reportDateRangeProvider);
    // Resync local pending fields whenever the range changed from
    // outside this card (e.g. a tab switch set a new default range).
    if (_lastSyncedRange != range) {
      _lastSyncedRange = range;
      _from = range.start;
      _to = range.end;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Filters'),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _dateField('FROM', _from ?? range.start, () => _pickDate(isFrom: true))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _dateField('TO', _to ?? range.end, () => _pickDate(isFrom: false))),
              const SizedBox(width: AppSpacing.md),
              PrimaryButton(label: 'Generate', icon: Icons.search_rounded, onPressed: _generate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(_fmt(value), style: AppTypography.body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
