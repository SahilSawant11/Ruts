import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/dashboard_providers.dart';
import '../../data/models/dashboard_summary_dto.dart';

enum _HeatmapMode { count, amount }

const double _heatmapCellSize = 12.0;
const double _heatmapCellGap = 4.0;

class TransactionActivityHeatmapCard extends ConsumerStatefulWidget {
  const TransactionActivityHeatmapCard({super.key});

  @override
  ConsumerState<TransactionActivityHeatmapCard> createState() =>
      _TransactionActivityHeatmapCardState();
}

class _TransactionActivityHeatmapCardState
    extends ConsumerState<TransactionActivityHeatmapCard> {
  _HeatmapMode _mode = _HeatmapMode.count;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Transaction Activity',
            subtitle: 'Last 12 months · ${_mode == _HeatmapMode.count ? 'bill count' : 'amount'}',
            trailing: _ModeToggle(
              mode: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          summaryAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'Could not load transaction activity.',
                  style: AppTypography.bodyMuted,
                ),
              ),
            ),
            data: (summary) {
              if (summary.transactionActivity.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'No transaction history available yet.',
                      style: AppTypography.bodyMuted.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ),
                );
              }
              return _Heatmap(
                points: summary.transactionActivity,
                mode: _mode,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mode,
    required this.onChanged,
  });

  final _HeatmapMode mode;
  final ValueChanged<_HeatmapMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            label: 'Count',
            selected: mode == _HeatmapMode.count,
            onTap: () => onChanged(_HeatmapMode.count),
          ),
          const SizedBox(width: 4),
          _ToggleButton(
            label: 'Amount',
            selected: mode == _HeatmapMode.amount,
            onTap: () => onChanged(_HeatmapMode.amount),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: selected
                ? AppColors.primary
                : AppColors.textSecondaryFor(context),
          ),
        ),
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({
    required this.points,
    required this.mode,
  });

  final List<TransactionActivityDayDto> points;
  final _HeatmapMode mode;

  static const _weekdayLabels = <int, String>{
    DateTime.monday: 'Mon',
    DateTime.wednesday: 'Wed',
    DateTime.friday: 'Fri',
  };
  static const _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks();
    final maxValue = _maxMetric();
    final totalCount = points.fold<int>(0, (sum, point) => sum + point.billCount);
    final totalAmount = points.fold<double>(0, (sum, point) => sum + point.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                mode == _HeatmapMode.count
                    ? '$totalCount transactions in the last year'
                    : '₹${totalAmount.toStringAsFixed(0)} billed in the last year',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _MetricChip(label: 'Transactions', value: '$totalCount'),
                _MetricChip(label: 'Amount', value: '₹${totalAmount.toStringAsFixed(0)}'),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            const rowLabelWidth = 40.0;
            const frameHorizontalPadding = 20.0;
            final availableGridWidth = math.max(
              0.0,
              constraints.maxWidth - frameHorizontalPadding,
            );
            final maxColumns = ((availableGridWidth - rowLabelWidth + _heatmapCellGap) /
                    (_heatmapCellSize + _heatmapCellGap))
                .floor()
                .clamp(0, weeks.length);
            final visibleWeeks = maxColumns > 0 && weeks.length > maxColumns
                ? weeks.sublist(weeks.length - maxColumns)
                : weeks;
            final monthMarkers = _monthMarkers(visibleWeeks);
            final gridWidth = rowLabelWidth +
                (visibleWeeks.length * _heatmapCellSize) +
                ((visibleWeeks.length - 1).clamp(0, 999) * _heatmapCellGap);
            final safeRowWidth = math.max(0.0, gridWidth - 2);

            return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: gridWidth + frameHorizontalPadding,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 18,
                      width: gridWidth,
                      child: Padding(
                        padding: const EdgeInsets.only(left: rowLabelWidth),
                        child: Stack(
                          children: [
                            for (final marker in monthMarkers)
                              Positioned(
                                left: marker.column * (_heatmapCellSize + _heatmapCellGap),
                                child: Text(
                                  marker.label,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textMutedFor(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (var weekday = DateTime.monday;
                        weekday <= DateTime.sunday;
                        weekday++)
                      Padding(
                        padding: EdgeInsets.only(bottom: weekday == DateTime.sunday ? 0 : 4),
                        child: ClipRect(
                          child: SizedBox(
                            width: safeRowWidth,
                            height: _heatmapCellSize,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  width: rowLabelWidth,
                                  height: _heatmapCellSize,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _weekdayLabels[weekday] ?? '',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textMutedFor(context),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                ...visibleWeeks.asMap().entries.map(
                                  (entry) {
                                    final index = entry.key;
                                    final week = entry.value;
                                    return Positioned(
                                      left: rowLabelWidth + index * (_heatmapCellSize + _heatmapCellGap),
                                      top: 0,
                                      width: _heatmapCellSize,
                                      height: _heatmapCellSize,
                                      child: _DayCell(
                                        point: week[weekday - 1],
                                        intensity: _intensity(week[weekday - 1], maxValue),
                                        mode: mode,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Less',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMutedFor(context),
                ),
              ),
              const SizedBox(width: 8),
              for (var i = 0; i < 5; i++) ...[
                _LegendCell(level: i / 4),
                if (i < 4) const SizedBox(width: 6),
              ],
              const SizedBox(width: 8),
              Text(
                'More',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMutedFor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<List<TransactionActivityDayDto?>> _buildWeeks() {
    final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));
    final first = sorted.first.date;
    final mondayStart = first.subtract(Duration(days: first.weekday - DateTime.monday));
    final byDate = {
      for (final point in sorted)
        DateTime(point.date.year, point.date.month, point.date.day): point,
    };

    final weeks = <List<TransactionActivityDayDto?>>[];
    for (var week = 0; week < 54; week++) {
      final weekStart = mondayStart.add(Duration(days: week * 7));
      if (weekStart.isAfter(sorted.last.date)) break;
      weeks.add(
        List<TransactionActivityDayDto?>.generate(7, (index) {
          final date = DateTime(
            weekStart.year,
            weekStart.month,
            weekStart.day + index,
          );
          return byDate[date];
        }),
      );
    }
    return weeks;
  }

  double _maxMetric() {
    if (points.isEmpty) return 0;
    if (mode == _HeatmapMode.count) {
      return points.fold<int>(0, (max, point) => point.billCount > max ? point.billCount : max)
          .toDouble();
    }
    return points.fold<double>(0, (max, point) => point.amount > max ? point.amount : max);
  }

  double _intensity(TransactionActivityDayDto? point, double maxValue) {
    if (point == null || maxValue <= 0) return 0;
    final value = mode == _HeatmapMode.count ? point.billCount.toDouble() : point.amount;
    if (value <= 0) return 0;
    final normalized = (value / maxValue).clamp(0.0, 1.0);
    return normalized.toDouble();
  }

  List<_MonthMarker> _monthMarkers(List<List<TransactionActivityDayDto?>> weeks) {
    final markers = <_MonthMarker>[];
    int? previousMonth;
    var lastColumn = -99;
    for (var i = 0; i < weeks.length; i++) {
      final point = weeks[i].firstWhere((day) => day != null, orElse: () => null);
      if (point == null) continue;
      if (point.date.month != previousMonth && i - lastColumn >= 3) {
        markers.add(_MonthMarker(label: _months[point.date.month - 1], column: i));
        previousMonth = point.date.month;
        lastColumn = i;
      }
    }
    return markers;
  }
}

class _MonthMarker {
  const _MonthMarker({
    required this.label,
    required this.column,
  });

  final String label;
  final int column;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundFor(context),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMutedFor(context),
              ),
            ),
            TextSpan(
              text: value,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.point,
    required this.intensity,
    required this.mode,
  });

  final TransactionActivityDayDto? point;
  final double intensity;
  final _HeatmapMode mode;

  @override
  Widget build(BuildContext context) {
    final valueText = point == null
        ? 'No data'
        : mode == _HeatmapMode.count
            ? '${point!.billCount} transaction(s)'
            : '₹${point!.amount.toStringAsFixed(0)} billed';

    return Tooltip(
      message: point == null
          ? valueText
          : '${_formatDate(point!.date)}\n$valueText',
      child: Container(
        width: _heatmapCellSize,
        height: _heatmapCellSize,
        decoration: BoxDecoration(
          color: _heatColor(context, intensity),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: AppColors.borderFor(context),
            width: 0.7,
          ),
        ),
      ),
    );
  }

  Color _heatColor(BuildContext context, double level) {
    if (level <= 0) {
      return AppColors.surfaceAltFor(context);
    }
    if (level < 0.25) {
      return AppColors.primarySoft;
    }
    if (level < 0.5) {
      return AppColors.primary.withValues(alpha: 0.45);
    }
    if (level < 0.75) {
      return AppColors.chartIndigo.withValues(alpha: 0.8);
    }
    return AppColors.primaryDark;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}

class _LegendCell extends StatelessWidget {
  const _LegendCell({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    Color color;
    if (level <= 0) {
      color = AppColors.surfaceAltFor(context);
    } else if (level < 0.25) {
      color = AppColors.primarySoft;
    } else if (level < 0.5) {
      color = AppColors.primary.withValues(alpha: 0.45);
    } else if (level < 0.75) {
      color = AppColors.chartIndigo.withValues(alpha: 0.8);
    } else {
      color = AppColors.primaryDark;
    }

    return Container(
      width: _heatmapCellSize,
      height: _heatmapCellSize,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.borderFor(context), width: 0.7),
      ),
    );
  }
}
