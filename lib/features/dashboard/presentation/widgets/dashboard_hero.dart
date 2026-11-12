import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/data/fact_card.dart';
import '../../../../shared/widgets/data/figure.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../../inventory/data/inventory_providers.dart';
import '../../data/dashboard_providers.dart';
import '../../data/models/dashboard_summary_dto.dart';

/// The gold field at the top of the dashboard: the period's sales as one
/// big number with bills / average / returns under it, and four fact cards
/// (purchases, purchase returns, low stock, products) on the right.
/// Every period figure is compared with the equally long period before it.
class DashboardHero extends ConsumerWidget {
  const DashboardHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(dashboardPeriodProvider);
    final snapshot = ref.watch(dashboardSnapshotProvider);
    final summary = ref.watch(dashboardSummaryProvider).valueOrNull;
    final lowStock = ref.watch(inventoryLowStockCountProvider).valueOrNull ?? summary?.lowStockCount;

    return AppCard(
      tone: CardTone.gold,
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(builder: (context, c) {
        // Height grows with the Text size setting: a fixed part (padding,
        // icons, gaps) plus a part for text that scales with it.
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final height = 120 + 212 * textScale;
        final left = _SalesBlock(period: period, snapshot: snapshot);
        final right = _FactGrid(snapshot: snapshot, summary: summary, lowStock: lowStock);
        if (c.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: height, child: left),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(height: height, child: right)
            ],
          );
        }
        return SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: left),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 6, child: right),
            ],
          ),
        );
      }),
    );
  }
}

class _SalesBlock extends ConsumerWidget {
  const _SalesBlock({required this.period, required this.snapshot});
  final DashboardPeriod period;
  final AsyncValue<DashboardPeriodSnapshot> snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fg = AppCard.onColorFor(context, CardTone.gold);
    final muted = AppCard.mutedOnFor(context, CardTone.gold);
    final dark = AppColors.isDark(context);
    final s = snapshot.valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: AppTypography.h2.copyWith(color: fg, fontSize: 26)),
        const SizedBox(height: AppSpacing.sm),
        PillTabs<DashboardPeriod>(
          values: DashboardPeriod.values,
          selected: period,
          label: (p) => p.label,
          onSelected: (p) => ref.read(dashboardPeriodProvider.notifier).state = p,
          onGold: !dark,
          onInk: dark,
          dense: true,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Sales', style: AppTypography.body.copyWith(color: muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (snapshot.hasError)
          Text('Could not load: ${snapshot.error}', style: AppTypography.body.copyWith(color: fg))
        else
          Figure(
            s == null ? '—' : Money.inr(s.sales.current, decimals: 0, symbol: false),
            prefix: '₹',
            size: 64,
            color: fg,
          ),
        const SizedBox(height: 10),
        _DeltaPill(delta: s?.sales.deltaPercent, higherIsBetter: true, against: period.previousLabel),
        const Spacer(),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            _MiniStat(label: 'Bills', value: s == null ? '—' : '${s.billCount.current.toInt()}'),
            _MiniStat(label: 'Avg bill', value: s == null ? '—' : Money.inr(s.avgBillValue, decimals: 0)),
            _MiniStat(
              label: 'Sales Returns',
              value: s == null ? '—' : Money.inr(s.salesReturns.current, decimals: 0),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.caption.copyWith(color: AppCard.mutedOnFor(context, CardTone.gold), fontSize: 12)),
          const SizedBox(height: 4),
          Figure(value, size: 24, weight: FontWeight.w400, color: AppCard.onColorFor(context, CardTone.gold)),
        ],
      ),
    );
  }
}

/// "↑ 12% vs previous 7 days" on an ink pill; "—" when nothing to compare.
class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.delta, required this.higherIsBetter, required this.against});
  final double? delta;
  final bool? higherIsBetter;
  final String against;

  @override
  Widget build(BuildContext context) {
    final d = delta;
    final text = d == null ? '— vs $against' : '${d >= 0 ? '↑' : '↓'} ${d.abs().toStringAsFixed(0)}% vs $against';
    final dark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ShapeDecoration(color: dark ? AppColors.primary : AppColors.ink, shape: const StadiumBorder()),
      child: Text(text,
          style: AppTypography.caption
              .copyWith(color: dark ? AppColors.ink : AppColors.cream, fontWeight: FontWeight.w600)),
    );
  }
}

class _FactGrid extends StatelessWidget {
  const _FactGrid({required this.snapshot, required this.summary, required this.lowStock});
  final AsyncValue<DashboardPeriodSnapshot> snapshot;
  final DashboardSummaryDto? summary;
  final int? lowStock;

  static int _stockLevel(int n) => n == 0 ? 0 : (n <= 5 ? 1 : (n <= 15 ? 2 : 3));

  @override
  Widget build(BuildContext context) {
    final s = snapshot.valueOrNull;
    String money(PeriodMetric? m) => m == null ? '—' : Money.inr(m.current, decimals: 0, symbol: false);
    String delta(PeriodMetric? m) {
      final d = m?.deltaPercent;
      return d == null ? '—' : '${d >= 0 ? '↑' : '↓'} ${d.abs().toStringAsFixed(0)}%';
    }

    final cards = [
      FactCard(
        icon: AppIcons.purchaseBill,
        title: 'Purchases',
        value: money(s?.purchases),
        prefix: '₹',
        trailing: _TrailText(delta(s?.purchases)),
        onTap: () => context.go('/purchase'),
      ),
      FactCard(
        icon: AppIcons.purchaseReturn,
        title: 'Purchase Returns',
        value: money(s?.purchaseReturns),
        prefix: '₹',
        trailing: _TrailText(delta(s?.purchaseReturns)),
        onTap: () => context.go('/purchase-return'),
      ),
      FactCard(
        icon: AppIcons.warning,
        iconFill: (lowStock ?? 0) > 0 ? AppColors.chartRose : null,
        title: 'Low Stock',
        value: lowStock == null ? '—' : '$lowStock',
        unit: 'items',
        trailing: LevelDots(
          level: _stockLevel(lowStock ?? 0),
          label: switch (_stockLevel(lowStock ?? 0)) { 0 => 'All good', 1 => 'Low', 2 => 'Medium', _ => 'High' },
          color: AppColors.textPrimaryFor(context),
        ),
        onTap: () => context.go('/inventory'),
      ),
      FactCard(
        icon: AppIcons.materials,
        title: 'SCM Codes',
        value: summary == null ? '—' : '${summary!.materialCount}',
        trailing: _TrailText(summary == null ? '' : '${summary!.supplierCount} Suppliers'),
        onTap: () => context.go('/material'),
      ),
    ];

    return Column(
      children: [
        Expanded(
            child: Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])])),
        const SizedBox(height: 12),
        Expanded(
            child: Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])])),
      ],
    );
  }
}

class _TrailText extends StatelessWidget {
  const _TrailText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTypography.caption.copyWith(color: AppColors.textSecondaryFor(context), fontSize: 12));
}
