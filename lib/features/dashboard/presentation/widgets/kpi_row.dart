import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/dashboard_providers.dart';
import '../../data/models/dashboard_summary_dto.dart';

/// Period selector + the four headline numbers. Every figure is for the
/// selected period and compared with the equally long period before it.
class DashboardKpiRow extends ConsumerWidget {
  const DashboardKpiRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(dashboardPeriodProvider);
    final snapshot = ref.watch(dashboardSnapshotProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Overview',
              style: AppTypography.sectionTitle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryFor(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'compared with the ${period.previousLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: AppColors.textMutedFor(context)),
              ),
            ),
            const SizedBox(width: 10),
            DashboardPeriodSelector(
              value: period,
              onChanged: (p) => ref.read(dashboardPeriodProvider.notifier).state = p,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        snapshot.when(
          loading: () => const _KpiSkeletonRow(),
          error: (e, _) => _KpiError(message: '$e'),
          data: (s) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Sales',
                  metric: s.sales,
                  higherIsBetter: true,
                  icon: AppIcons.trendingUp,
                  iconColor: AppColors.primary,
                  footnote: s.billCount.current == 0
                      ? 'No bills'
                      : '${s.billCount.current.toInt()} bills · avg ${Money.compact(s.avgBillValue)}',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  title: 'Sales Returns',
                  metric: s.salesReturns,
                  higherIsBetter: false,
                  icon: AppIcons.salesReturn,
                  iconColor: AppColors.chartTeal,
                  footnote: s.sales.current + s.salesReturns.current == 0
                      ? 'No returns'
                      : '${(s.salesReturns.current / (s.sales.current + s.salesReturns.current) * 100).toStringAsFixed(1)}% of sales returned',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  title: 'Purchases',
                  metric: s.purchases,
                  higherIsBetter: null,
                  icon: AppIcons.purchaseBill,
                  iconColor: AppColors.chartAmber,
                  footnote: 'Stock received from suppliers',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  title: 'Purchase Returns',
                  metric: s.purchaseReturns,
                  higherIsBetter: null,
                  icon: AppIcons.purchaseReturn,
                  iconColor: AppColors.chartBlue,
                  footnote: 'Stock sent back to suppliers',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Segmented Today / 7 days / 30 days / 12 months control.
class DashboardPeriodSelector extends StatelessWidget {
  const DashboardPeriodSelector({super.key, required this.value, required this.onChanged});

  final DashboardPeriod value;
  final ValueChanged<DashboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAltFor(context),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in DashboardPeriod.values)
            GestureDetector(
              onTap: () => onChanged(p),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: p == value ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    p.label,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: p == value ? Colors.white : AppColors.textSecondaryFor(context),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.metric,
    required this.higherIsBetter,
    required this.icon,
    required this.iconColor,
    required this.footnote,
  });

  final String title;
  final PeriodMetric metric;

  /// true: up is good (green). false: up is bad (red). null: neutral.
  final bool? higherIsBetter;
  final AppIconData icon;
  final Color iconColor;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundFor(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderFor(context)),
        boxShadow: AppColors.cardShadowFor(context),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: AppIcon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
              _TrendBadge(delta: metric.deltaPercent, higherIsBetter: higherIsBetter),
            ],
          ),
          const SizedBox(height: 12),
          Tooltip(
            message: Money.inr(metric.current),
            child: Text(
              Money.compact(metric.current),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h1.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.textPrimaryFor(context),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'was ${Money.compact(metric.previous)} · $footnote',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: AppColors.textMutedFor(context), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.delta, required this.higherIsBetter});

  final double? delta;
  final bool? higherIsBetter;

  @override
  Widget build(BuildContext context) {
    final d = delta;
    if (d == null) {
      return Tooltip(
        message: 'No data in the previous period to compare with',
        child: _pill(context, '—', AppColors.textMutedFor(context), null),
      );
    }
    final up = d >= 0.5;
    final down = d <= -0.5;
    final good = higherIsBetter == null ? null : (higherIsBetter! ? up : down);
    final bad = higherIsBetter == null ? null : (higherIsBetter! ? down : up);
    final color = good == true
        ? AppColors.success
        : bad == true
            ? AppColors.danger
            : AppColors.textSecondaryFor(context);
    final pct = d.abs() >= 1000 ? '999+%' : '${d.abs().toStringAsFixed(d.abs() < 10 ? 1 : 0)}%';
    return _pill(context, pct, color, up ? AppIcons.arrowUp : (down ? AppIcons.arrowDown : null));
  }

  Widget _pill(BuildContext context, String text, Color color, AppIconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon(icon, size: 11, color: color),
            const SizedBox(width: 2),
          ],
          Text(text, style: AppTypography.mono.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _KpiSkeletonRow extends StatelessWidget {
  const _KpiSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              height: 112,
              decoration: BoxDecoration(
                color: AppColors.surfaceAltFor(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _KpiError extends StatelessWidget {
  const _KpiError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text('Could not load figures: $message', style: AppTypography.body.copyWith(color: AppColors.danger)),
      );
}
