import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/dashboard_providers.dart';

/// Top categories for the selected dashboard period, ranked by sales, with
/// each category's share of total sales in that period.
class TopCategoriesCard extends ConsumerWidget {
  const TopCategoriesCard({super.key});

  static const _barColors = [
    Color(0xFF2EBD85),
    Color(0xFF6C5CE7),
    Color(0xFFF5A623),
    Color(0xFF4A9FF5),
    Color(0xFFE96560),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final snapshot = ref.watch(dashboardSnapshotProvider);
    final period = ref.watch(dashboardPeriodProvider);

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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF2EBD85).withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const AppIcon(AppIcons.categories, size: 16, color: Color(0xFF2EBD85)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Top Categories',
                  style: AppTypography.sectionTitle.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
              ),
              Text(period.label, style: AppTypography.caption.copyWith(color: AppColors.textMutedFor(context))),
            ],
          ),
          const SizedBox(height: 14),
          snapshot.when(
            loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, _) => SizedBox(height: 120, child: Center(child: Text('Could not load: $e'))),
            data: (s) {
              final cats = s.categoryBreakdown;
              final total = cats.fold<double>(0, (t, c) => t + c.amount);
              if (cats.isEmpty || total <= 0) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'No sales in this period',
                      style: AppTypography.body.copyWith(color: AppColors.textMutedFor(context)),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < cats.length && i < 5; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _CategoryBar(
                      name: cats[i].category.isEmpty ? 'Uncategorised' : cats[i].category,
                      amount: cats[i].amount,
                      share: cats[i].amount / total,
                      color: _barColors[i % _barColors.length],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.name, required this.amount, required this.share, required this.color});

  final String name;
  final double amount;
  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$name · ${Money.inr(amount)} · ${(share * 100).toStringAsFixed(1)}% of sales',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
              ),
              Text(
                Money.compact(amount),
                style: AppTypography.mono.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${(share * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: AppTypography.mono.copyWith(fontSize: 11, color: AppColors.textMutedFor(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: share.clamp(0.0, 1.0),
              minHeight: 6,
              color: color,
              backgroundColor: AppColors.surfaceAltFor(context),
            ),
          ),
        ],
      ),
    );
  }
}
