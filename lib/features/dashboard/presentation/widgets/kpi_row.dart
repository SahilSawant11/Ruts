import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/dashboard_providers.dart';

/// Top 4 elevated KPI cards matching the mood board design:
///  1. Total Sales (with trend + dropdown + 'View all ↗')
///  2. Sales Return (with trend + dropdown + 'View all ↗')
///  3. Total Purchase (with trend + dropdown + 'View all ↗')
///  4. Purchase Return (with trend + dropdown + 'View all ↗')
class DashboardKpiRow extends ConsumerStatefulWidget {
  const DashboardKpiRow({super.key});

  @override
  ConsumerState<DashboardKpiRow> createState() => _DashboardKpiRowState();
}

class _DashboardKpiRowState extends ConsumerState<DashboardKpiRow> {
  String _timeframe = 'Weekly';

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return summaryAsync.when(
      loading: () => const _KpiSkeletonRow(),
      error: (_, __) => const _KpiSkeletonRow(),
      data: (summary) {
        // Sales value by timeframe
        final salesVal = switch (_timeframe) {
          'Today' => summary.todaySales,
          'Monthly' => summary.totalSalesMonth > 0
              ? summary.totalSalesMonth
              : summary.todaySales,
          _ => summary.totalSalesWeek > 0
              ? summary.totalSalesWeek
              : summary.todaySales,
        };

        // Purchase value by timeframe
        final purchaseVal = switch (_timeframe) {
          'Today' => summary.totalPurchase,
          'Monthly' => summary.totalPurchase,
          _ => summary.totalPurchase,
        };

        final salesReturnVal = summary.salesReturnAmount;
        final purchaseReturnVal = summary.purchaseReturnAmount;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1 — Total Sales
            Expanded(
              child: _MetricCard(
                title: 'Total Sales',
                value: '₹ ${_formatRupee(salesVal)}',
                trendPercent: summary.salesDeltaPercent ?? 0.0,
                isTrendUp: (summary.salesDeltaPercent ?? 0.0) >= 0,
                subtitle: 'Sales vs last period',
                icon: Icons.monetization_on_outlined,
                iconColor: AppColors.primary,
                selectedTimeframe: _timeframe,
                onTimeframeChanged: (v) =>
                    setState(() => _timeframe = v),
                onViewAll: () => context.go('/sales'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Card 2 — Sales Return
            Expanded(
              child: _MetricCard(
                title: 'Sales Return',
                value: '₹ ${_formatRupee(salesReturnVal)}',
                trendPercent: summary.salesReturnDeltaPercent ?? 0.0,
                isTrendUp: false,
                subtitle: 'Sales return vs last period',
                icon: Icons.sync_rounded,
                iconColor: AppColors.chartTeal,
                selectedTimeframe: _timeframe,
                onTimeframeChanged: (v) =>
                    setState(() => _timeframe = v),
                onViewAll: () => context.go('/sales-return'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Card 3 — Total Purchase
            Expanded(
              child: _MetricCard(
                title: 'Total Purchase',
                value: '₹ ${_formatRupee(purchaseVal)}',
                trendPercent: summary.purchaseDeltaPercent ?? 0.0,
                isTrendUp: true,
                subtitle: 'Purchase vs last period',
                icon: Icons.shopping_bag_outlined,
                iconColor: AppColors.chartAmber,
                selectedTimeframe: _timeframe,
                onTimeframeChanged: (v) =>
                    setState(() => _timeframe = v),
                onViewAll: () => context.go('/purchase'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Card 4 — Purchase Return
            Expanded(
              child: _MetricCard(
                title: 'Purchase Return',
                value: '₹ ${_formatRupee(purchaseReturnVal)}',
                trendPercent: summary.purchaseReturnDeltaPercent ?? 0.0,
                isTrendUp: false,
                subtitle: 'Purchase return vs last period',
                icon: Icons.swap_horiz_rounded,
                iconColor: AppColors.chartBlue,
                selectedTimeframe: _timeframe,
                onTimeframeChanged: (v) =>
                    setState(() => _timeframe = v),
                onViewAll: () => context.go('/purchase-return'),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _formatRupee(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)} L';
    if (v >= 1000) {
      final s = v.toInt().toString();
      final last3 = s.substring(s.length - 3);
      final rest = s.substring(0, s.length - 3);
      return '$rest,$last3';
    }
    return v.toStringAsFixed(0);
  }
}

// ── Elevated KPI Card Shell ──────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.trendPercent,
    required this.isTrendUp,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
    required this.onViewAll,
  });

  final String title;
  final String value;
  final double trendPercent;
  final bool isTrendUp;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String selectedTimeframe;
  final ValueChanged<String> onTimeframeChanged;
  final VoidCallback onViewAll;

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
          // Top Row: Title + Timeframe Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Compact timeframe dropdown pill
              _TimeframePill(
                value: selectedTimeframe,
                onChanged: onTimeframeChanged,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Metric Row: Icon + Value + Trend Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tinted Circular Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? iconColor.withValues(alpha: 0.20)
                      : iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19, color: iconColor),
              ),
              const SizedBox(width: 10),

              // Value
              Expanded(
                child: Text(
                  value,
                  style: AppTypography.h1.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimaryFor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Inline Trend Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isTrendUp
                      ? (isDark
                          ? AppColors.success.withValues(alpha: 0.16)
                          : AppColors.successSoft)
                      : (isDark
                          ? AppColors.danger.withValues(alpha: 0.16)
                          : AppColors.dangerSoft),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTrendUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 11,
                      color: isTrendUp ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${trendPercent.abs().toStringAsFixed(0)}%',
                      style: AppTypography.mono.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color:
                            isTrendUp ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bottom Row: Subtitle + 'View all ↗'
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedFor(context),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'View all',
                        style: AppTypography.label.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.north_east_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Timeframe Dropdown Pill ──────────────────────────────────────────────────

class _TimeframePill extends StatelessWidget {
  const _TimeframePill({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          dropdownColor: AppColors.surfaceFor(context),
          style: AppTypography.body.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryFor(context),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 15,
            color: AppColors.textMutedFor(context),
          ),
          items: const [
            DropdownMenuItem(value: 'Today', child: Text('Today')),
            DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
            DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Skeleton Loader ──────────────────────────────────────────────────────────

class _KpiSkeletonRow extends StatelessWidget {
  const _KpiSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        4,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 3 ? AppSpacing.md : 0),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceFor(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderFor(context)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
