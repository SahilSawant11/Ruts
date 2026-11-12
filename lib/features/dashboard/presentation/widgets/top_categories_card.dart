import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/data/figure.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/dashboard_providers.dart';

/// Top categories for the selected dashboard period as rounded bar blocks:
/// value above, category pill below. The leader is ink, the rest gold tones.
class TopCategoriesCard extends ConsumerWidget {
  const TopCategoriesCard({super.key});

  static const double _chartHeight = 236;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dashboardSnapshotProvider);
    final period = ref.watch(dashboardPeriodProvider);
    final dark = AppColors.isDark(context);
    final fills = [
      dark ? AppColors.cream : AppColors.ink,
      AppColors.primary,
      AppColors.primary.withValues(alpha: 0.6),
      AppColors.primary.withValues(alpha: 0.35),
      AppColors.primary.withValues(alpha: 0.2),
    ];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Top Categories',
                    style: AppTypography.sectionTitle
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textPrimaryFor(context))),
              ),
              Text(period.label, style: AppTypography.caption.copyWith(color: AppColors.textMutedFor(context))),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: _chartHeight,
            child: snapshot.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(child: Text('Could not load: $e')),
              data: (s) {
                final cats = s.categoryBreakdown.take(5).toList();
                final total = s.categoryBreakdown.fold<double>(0, (t, c) => t + c.amount);
                if (cats.isEmpty || total <= 0) {
                  return Center(
                    child: Text('No sales in this period',
                        style: AppTypography.body.copyWith(color: AppColors.textMutedFor(context))),
                  );
                }
                final maxAmount = cats.map((c) => c.amount).reduce((a, b) => a > b ? a : b);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < cats.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _BarBlock(
                          name: cats[i].category.isEmpty ? 'Uncategorised' : cats[i].category,
                          amount: cats[i].amount,
                          share: cats[i].amount / total,
                          height: cats[i].amount / maxAmount,
                          fill: fills[i],
                          onFillText: i == 0 ? (dark ? AppColors.ink : AppColors.cream) : AppColors.ink,
                          leader: i == 0,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BarBlock extends StatelessWidget {
  const _BarBlock({
    required this.name,
    required this.amount,
    required this.share,
    required this.height,
    required this.fill,
    required this.onFillText,
    required this.leader,
  });

  final String name;
  final double amount;
  final double share;
  final double height; // 0–1 relative to the leader
  final Color fill;
  final Color onFillText;
  final bool leader;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$name · ${Money.inr(amount)} · ${(share * 100).toStringAsFixed(1)}% of sales',
      child: LayoutBuilder(builder: (context, c) {
        const labelH = 34.0, valueH = 24.0;
        final barMax = c.maxHeight - labelH - valueH - 8;
        final barH = (barMax * height).clamp(28.0, barMax);
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: valueH,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Figure(Money.compact(amount, symbol: false), prefix: '₹', size: 17,
                    weight: leader ? FontWeight.w600 : FontWeight.w400),
              ),
            ),
            Container(
              height: barH,
              width: double.infinity,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(16)),
              child: barH > 40
                  ? Text('${(share * 100).round()}%',
                      style: AppTypography.caption.copyWith(color: onFillText, fontWeight: FontWeight.w700))
                  : null,
            ),
            const SizedBox(height: 8),
            Container(
              height: labelH - 4,
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: ShapeDecoration(
                color: leader ? AppColors.textPrimaryFor(context) : Colors.transparent,
                shape: StadiumBorder(side: BorderSide(color: leader ? Colors.transparent : AppColors.borderFor(context))),
              ),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: leader ? AppColors.backgroundFor(context) : AppColors.textPrimaryFor(context),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
