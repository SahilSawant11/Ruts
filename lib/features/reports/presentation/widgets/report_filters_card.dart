import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../../masters/data/masters_providers.dart';
import '../../data/reports_providers.dart';

/// From/To date range picker + Generate button. Picking dates only
/// updates local pending state — Generate is what actually commits
/// the new range to reportDateRangeProvider (and triggers the fetch),
/// so the report doesn't refire on every single date tap.
class ReportFiltersCard extends ConsumerStatefulWidget {
  const ReportFiltersCard({
    super.key,
    this.tabs,
    this.trailingAction,
  });

  final Widget? tabs;
  final Widget? trailingAction;

  @override
  ConsumerState<ReportFiltersCard> createState() => _ReportFiltersCardState();
}

class _ReportFiltersCardState extends ConsumerState<ReportFiltersCard> {
  DateTime? _from;
  DateTime? _to;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;
  DateTimeRange? _lastSyncedRange;
  String? _category;
  String? _lastSyncedCategory;
  String? _manufacturer;
  String? _lastSyncedManufacturer;

  String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')}-${months[d.month - 1]}-${d.year}';
  }

  String _fmtTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
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

  Future<void> _pickTime({required bool isFrom}) async {
    final initial = isFrom
        ? (_fromTime ?? const TimeOfDay(hour: 0, minute: 0))
        : (_toTime ?? const TimeOfDay(hour: 23, minute: 59));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromTime = picked;
      } else {
        _toTime = picked;
      }
    });
  }

  void _generate() {
    if (_from == null || _to == null) return;
    final fromDate = _from!.isAfter(_to!) ? _to! : _from!;
    final toDate = _from!.isAfter(_to!) ? _from! : _to!;
    final fromTime = _fromTime ?? const TimeOfDay(hour: 0, minute: 0);
    final toTime = _toTime ?? const TimeOfDay(hour: 23, minute: 59);

    final from = DateTime(
      fromDate.year,
      fromDate.month,
      fromDate.day,
      fromTime.hour,
      fromTime.minute,
      0,
    );
    final to = DateTime(
      toDate.year,
      toDate.month,
      toDate.day,
      toTime.hour,
      toTime.minute,
      59,
      999,
    );

    ref.read(reportDateRangeProvider.notifier).state = DateTimeRange(start: from, end: to);
    ref.read(reportCategoryFilterProvider.notifier).state = _category;
    ref.read(reportManufacturerFilterProvider.notifier).state = _manufacturer;
    ref.invalidate(salesReportProvider);
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(reportDateRangeProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final manufacturersAsync = ref.watch(manufacturersListProvider);
    final activeCategory = ref.watch(reportCategoryFilterProvider);
    final activeManufacturer = ref.watch(reportManufacturerFilterProvider);

    // Resync local pending fields whenever the range changed from
    // outside this card (e.g. a tab switch set a new default range).
    if (_lastSyncedRange != range) {
      _lastSyncedRange = range;
      _from = range.start;
      _to = range.end;
      _fromTime = TimeOfDay(hour: range.start.hour, minute: range.start.minute);
      _toTime = TimeOfDay(hour: range.end.hour, minute: range.end.minute);
    }
    if (_lastSyncedCategory != activeCategory) {
      _lastSyncedCategory = activeCategory;
      _category = activeCategory;
    }
    if (_lastSyncedManufacturer != activeManufacturer) {
      _lastSyncedManufacturer = activeManufacturer;
      _manufacturer = activeManufacturer;
    }

    final fromDateVal = _from ?? range.start;
    final toDateVal = _to ?? range.end;
    final fromTimeVal = _fromTime ?? TimeOfDay(hour: range.start.hour, minute: range.start.minute);
    final toTimeVal = _toTime ?? TimeOfDay(hour: range.end.hour, minute: range.end.minute);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Filters',
            trailing: (widget.tabs != null || widget.trailingAction != null)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.tabs != null) widget.tabs!,
                      if (widget.trailingAction != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        widget.trailingAction!,
                      ],
                    ],
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1050;

              final fromDateWidget = _pickerField(
                label: 'FROM DATE',
                value: _fmtDate(fromDateVal),
                icon: Icons.calendar_today_outlined,
                onTap: () => _pickDate(isFrom: true),
              );

              final fromTimeWidget = _pickerField(
                label: 'FROM TIME',
                value: _fmtTime(fromTimeVal),
                icon: Icons.access_time_rounded,
                onTap: () => _pickTime(isFrom: true),
              );

              final toDateWidget = _pickerField(
                label: 'TO DATE',
                value: _fmtDate(toDateVal),
                icon: Icons.calendar_today_outlined,
                onTap: () => _pickDate(isFrom: false),
              );

              final toTimeWidget = _pickerField(
                label: 'TO TIME',
                value: _fmtTime(toTimeVal),
                icon: Icons.access_time_rounded,
                onTap: () => _pickTime(isFrom: false),
              );

              final categoryWidget = categoriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (categories) => AppDropdown<String>(
                  label: 'CATEGORY',
                  items: categories.map((category) => category.name).toList(),
                  itemLabel: (value) => value,
                  value: _category,
                  hint: 'All categories',
                  onChanged: (value) => setState(() => _category = value),
                ),
              );

              final manufacturerWidget = manufacturersAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (manufacturers) => AppDropdown<String>(
                  label: 'MANUFACTURER',
                  items: manufacturers.map((manufacturer) => manufacturer.name).toList(),
                  itemLabel: (value) => value,
                  value: _manufacturer,
                  hint: 'All manufacturers',
                  onChanged: (value) => setState(() => _manufacturer = value),
                ),
              );

              final generateButton = PrimaryButton(
                label: 'Generate',
                icon: Icons.search_rounded,
                onPressed: _generate,
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(flex: 3, child: fromDateWidget),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(flex: 2, child: fromTimeWidget),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 3, child: toDateWidget),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(flex: 2, child: toTimeWidget),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 3, child: categoryWidget),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 3, child: manufacturerWidget),
                    const SizedBox(width: AppSpacing.md),
                    generateButton,
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(flex: 3, child: fromDateWidget),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(flex: 2, child: fromTimeWidget),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(flex: 3, child: toDateWidget),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(flex: 2, child: toTimeWidget),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: categoryWidget),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: manufacturerWidget),
                      const SizedBox(width: AppSpacing.md),
                      generateButton,
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _pickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderFor(context)),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: AppColors.textMutedFor(context),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimaryFor(context),
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
