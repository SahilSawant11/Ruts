import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/data/figure.dart';
import '../../data/dashboard_providers.dart';
import '../../data/models/dashboard_summary_dto.dart';

/// "Today so far" on a soft warm gradient (wheat → gold → amber): today's
/// sales, bills, average bill, the busiest two hours, and yesterday's full
/// day as a plain reference — not a % delta, because half a day against a
/// whole one always looks like a drop until closing time.
class TodayCard extends ConsumerWidget {
  const TodayCard({super.key});

  /// Matte, no gloss: a vertical warm blend with a soft light corner.
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBEFD6), Color(0xFFF6C35E), Color(0xFFEE9B45)],
    stops: [0.0, 0.55, 1.0],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(dashboardSummaryProvider).valueOrNull;
    const ink = AppColors.ink;
    final muted = ink.withValues(alpha: 0.62);

    return Container(
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: () => context.go('/sales'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today so far',
                              style: AppTypography.sectionTitle
                                  .copyWith(color: ink, fontWeight: FontWeight.w700, fontSize: 17)),
                          const SizedBox(height: 2),
                          Text(_dateLabel(DateTime.now()), style: AppTypography.caption.copyWith(color: muted)),
                        ],
                      ),
                    ),
                    CircleIconButton(
                      size: 34,
                      color: ink,
                      tooltip: 'Open Sales Bill',
                      onTap: () => context.go('/sales'),
                      child: const AppIcon(AppIcons.northEast, size: 15, color: ink),
                    ),
                  ],
                ),
                const Spacer(),
                Text('Sales', style: AppTypography.body.copyWith(color: muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Figure(
                    s == null ? '—' : Money.inr(s.todaySales, decimals: 0, symbol: false),
                    prefix: '₹',
                    size: 52,
                    color: ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _Stat(label: 'Bills', value: s == null ? '—' : '${s.todayBillCount}'),
                    _Stat(label: 'Avg bill', value: s == null ? '—' : Money.inr(s.avgBillValue, decimals: 0)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: ink.withValues(alpha: 0.12)),
                const SizedBox(height: AppSpacing.sm),
                _Line(label: 'Busiest', value: s == null ? '—' : busiestSlot(s.dailyComparison) ?? 'No sales yet'),
                const SizedBox(height: 4),
                _Line(label: 'Yesterday', value: s == null ? '—' : yesterdayLabel(s.weeklyComparison)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _dateLabel(DateTime d) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  /// The 2-hour slot with the most sales today, e.g. "7 PM – 9 PM",
  /// "Until 11 AM" or "After 9 PM"; null when nothing has sold yet.
  static String? busiestSlot(List<MonthlyComparisonPointDto> slots) {
    if (slots.isEmpty) return null;
    var bestIndex = 0;
    for (var i = 1; i < slots.length; i++) {
      if (slots[i].salesAmount > slots[bestIndex].salesAmount) bestIndex = i;
    }
    final best = slots[bestIndex];
    if (best.salesAmount <= 0) return null;
    // The first and last slots are open-ended (they include early and
    // late bills), so name them that way.
    if (slots.length > 1 && bestIndex == 0) return 'Until ${slots[1].month}';
    if (slots.length > 1 && bestIndex == slots.length - 1) return 'After ${best.month}';
    final m = RegExp(r'^(\d+) (AM|PM)$').firstMatch(best.month);
    if (m == null) return best.month;
    var h24 = int.parse(m.group(1)!) % 12 + (m.group(2) == 'PM' ? 12 : 0);
    h24 = (h24 + 2) % 24;
    final end = '${h24 % 12 == 0 ? 12 : h24 % 12} ${h24 >= 12 ? 'PM' : 'AM'}';
    return '${best.month} – $end';
  }

  /// Yesterday's full-day sales from the last-7-days series (index 5 of 7).
  static String yesterdayLabel(List<MonthlyComparisonPointDto> week) =>
      week.length < 2 ? '—' : Money.inr(week[week.length - 2].salesAmount, decimals: 0);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.ink.withValues(alpha: 0.62))),
            const SizedBox(height: 2),
            Figure(value, size: 22, weight: FontWeight.w400, color: AppColors.ink),
          ],
        ),
      );
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.ink.withValues(alpha: 0.62))),
          const Spacer(),
          Text(value,
              style: AppTypography.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ],
      );
}
