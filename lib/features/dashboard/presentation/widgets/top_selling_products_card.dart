import 'package:flutter/material.dart';
import '../../../../core/format/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/dashboard_providers.dart';

/// 'Top Selling Products' Card matching the mood board:
///  - Header with pink box icon & Weekly dropdown
///  - Ranked product rows with thumbnails, prices, sales counts, and trend badges
class TopSellingProductsCard extends ConsumerStatefulWidget {
  const TopSellingProductsCard({super.key});

  @override
  ConsumerState<TopSellingProductsCard> createState() => _TopSellingProductsCardState();
}

class _TopSellingProductsCardState extends ConsumerState<TopSellingProductsCard> {
  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSnapshotProvider);
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
          // Header: Box Icon + Title + Timeframe Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFFE96560).withValues(alpha: 0.20) : const Color(0xFFFFECEB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const AppIcon(
                      AppIcons.crate,
                      size: 16,
                      color: Color(0xFFE96560),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Top Selling Products',
                    style: AppTypography.sectionTitle.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimaryFor(context),
                    ),
                  ),
                ],
              ),
              Text(
                ref.watch(dashboardPeriodProvider).label,
                style: AppTypography.caption.copyWith(color: AppColors.textMutedFor(context)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Product List
          summaryAsync.when(
            loading: () => const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox(
              height: 180,
              child: Center(child: Text('—')),
            ),
            data: (summary) {
              final items = summary.topSellingItems;
              if (items.isEmpty) {
                return SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'No sales in this period',
                      style: AppTypography.body.copyWith(color: AppColors.textMutedFor(context)),
                    ),
                  ),
                );
              }
              final totalUnits = items.fold<int>(0, (sum, i) => sum + i.qty);

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length.clamp(0, 4),
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final sharePercent = totalUnits > 0 ? ((item.qty / totalUnits) * 100).round() : 0;

                  return _ProductRow(
                    name: item.materialName,
                    price: item.amount,
                    salesCount: item.qty,
                    trendPercent: sharePercent,
                    isPositive: true,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.name,
    required this.price,
    required this.salesCount,
    required this.trendPercent,
    required this.isPositive,
  });

  final String name;
  final double price;
  final int salesCount;
  final int trendPercent;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    // Initial letters for clean modern thumbnail
    final initials = name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

    return Row(
      children: [
        // Rounded Square Thumbnail Container
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232734) : const Color(0xFFF1F1F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderFor(context)),
          ),
          alignment: Alignment.center,
          child: Text(
            initials.isNotEmpty ? initials : 'PR',
            style: AppTypography.mono.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Product Name + Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$salesCount sold  ·  ${Money.compact(price)}',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.textMutedFor(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Share of units sold among the top products (neutral — not a trend).
        Tooltip(
          message: '$trendPercent% of units among the top products',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySoftFor(context),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$trendPercent%',
              style: AppTypography.mono.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
