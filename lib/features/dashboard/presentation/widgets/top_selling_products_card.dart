import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/dashboard_providers.dart';
import '../../data/models/dashboard_summary_dto.dart';

/// 'Top Selling Products' Card matching the mood board:
///  - Header with pink box icon & Weekly dropdown
///  - Ranked product rows with thumbnails, prices, sales counts, and trend badges
class TopSellingProductsCard extends ConsumerStatefulWidget {
  const TopSellingProductsCard({super.key});

  @override
  ConsumerState<TopSellingProductsCard> createState() =>
      _TopSellingProductsCardState();
}

class _TopSellingProductsCardState
    extends ConsumerState<TopSellingProductsCard> {
  String _timeframe = 'Weekly';

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
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
                      color: isDark
                          ? const Color(0xFFE96560).withValues(alpha: 0.20)
                          : const Color(0xFFFFECEB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
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

              // Dropdown
              Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _timeframe,
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
                      if (v != null) setState(() => _timeframe = v);
                    },
                  ),
                ),
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
              final items = summary.topSellingItems.isNotEmpty
                  ? summary.topSellingItems
                  : _fallbackItems();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length.clamp(0, 4),
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isPositive = index % 2 == 0;
                  final trendVal = index == 0 ? 25 : (index == 1 ? 28 : 15);

                  return _ProductRow(
                    name: item.materialName,
                    price: (item.amount / (item.qty > 0 ? item.qty : 1)),
                    salesCount: item.qty,
                    trendPercent: trendVal,
                    isPositive: isPositive,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  static List<TopSellingItemDto> _fallbackItems() {
    return const [
      TopSellingItemDto(
        materialName: 'Charger Cable - Lighting',
        manufacturer: 'Apple',
        qty: 247,
        amount: 46189,
      ),
      TopSellingItemDto(
        materialName: 'Yves Saint Eau De Parfum',
        manufacturer: 'YSL',
        qty: 300,
        amount: 43500,
      ),
      TopSellingItemDto(
        materialName: 'KitchenAid Stand Mixer',
        manufacturer: 'KitchenAid',
        qty: 180,
        amount: 72000,
      ),
    ];
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
                '₹ ${price.toStringAsFixed(0)}  ·  $salesCount+ Sales',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.textMutedFor(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Trend Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPositive
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
                isPositive
                    ? Icons.north_east_rounded
                    : Icons.south_east_rounded,
                size: 11,
                color: isPositive ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 3),
              Text(
                '$trendPercent%',
                style: AppTypography.mono.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isPositive ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
