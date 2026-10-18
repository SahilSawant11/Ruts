import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/dashboard_providers.dart';
import '../../data/models/dashboard_summary_dto.dart';

/// 'Top Categories' Card matching the visual composition of the mood board:
///  - Header with Category icon & Timeframe dropdown
///  - Dual visual vertical pillar cards (Green/Teal for Top Category vs Coral for 2nd Category)
///  - Right metrics column with revenue amounts, growth/share pill (↗ 65%), and category labels
class TopCategoriesCard extends StatefulWidget {
  const TopCategoriesCard({super.key});

  @override
  State<TopCategoriesCard> createState() => _TopCategoriesCardState();
}

class _TopCategoriesCardState extends State<TopCategoriesCard> {
  String _timeframe = 'Weekly';

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
          // Header: Category Icon + Title + Timeframe Dropdown
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
                          ? const Color(0xFF2EBD85).withValues(alpha: 0.20)
                          : const Color(0xFFE8F8F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      size: 16,
                      color: Color(0xFF2EBD85),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Top Categories',
                    style: AppTypography.sectionTitle.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimaryFor(context),
                    ),
                  ),
                ],
              ),

              // Timeframe dropdown
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

          // Visual Pillar Cards + Metrics Row (Mood board visual composition)
          Consumer(
            builder: (context, ref, _) {
              final summaryAsync = ref.watch(dashboardSummaryProvider);

              return summaryAsync.when(
                loading: () => const SizedBox(
                  height: 110,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => const SizedBox(
                  height: 110,
                  child: Center(child: Text('—')),
                ),
                data: (summary) {
                  final categories = summary.categoryBreakdown.isNotEmpty
                      ? summary.categoryBreakdown
                      : _fallbackCategories();

                  final firstCat = categories.isNotEmpty
                      ? categories[0]
                      : const CategoryBreakdownItemDto(category: 'IMFL Spirits', amount: 54000);
                  final secondCat = categories.length > 1
                      ? categories[1]
                      : const CategoryBreakdownItemDto(category: 'Beer & Cider', amount: 28500);

                  final total = firstCat.amount + secondCat.amount;
                  final firstPercent = total > 0 ? ((firstCat.amount / total) * 100).round() : 65;
                  final secondPercent = 100 - firstPercent;

                  final secondHeight = (100.0 * (secondCat.amount / (firstCat.amount > 0 ? firstCat.amount : 1)))
                      .clamp(45.0, 85.0);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Visual Blocks (Green for Top Category & Coral for 2nd)
                      Expanded(
                        flex: 5,
                        child: SizedBox(
                          height: 110,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // 1st Category Pillar Card (Green)
                              Expanded(
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2EBD85),
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      Positioned(
                                        top: 12,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 22,
                                        bottom: 0,
                                        child: Container(
                                          width: 1,
                                          color: Colors.white.withValues(alpha: 0.35),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 2nd Category Pillar Card (Coral/Rose)
                              Expanded(
                                child: Container(
                                  height: secondHeight,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE96560),
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      Positioned(
                                        top: 10,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 18,
                                        bottom: 0,
                                        child: Container(
                                          width: 1,
                                          color: Colors.white.withValues(alpha: 0.35),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Metrics Column (Right side)
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1st Category Metric
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatRupee(firstCat.amount),
                                  style: AppTypography.h2.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimaryFor(context),
                                  ),
                                ),
                                // Share Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2EBD85),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.north_east_rounded,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '$firstPercent%',
                                        style: AppTypography.mono.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              firstCat.category.isNotEmpty ? firstCat.category : 'Top Category',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMutedFor(context),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 2nd Category Metric
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatRupee(secondCat.amount),
                                  style: AppTypography.h2.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimaryFor(context),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE96560),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    '$secondPercent%',
                                    style: AppTypography.mono.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              secondCat.category.isNotEmpty ? secondCat.category : 'Secondary Category',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMutedFor(context),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  static String _formatRupee(double v) {
    if (v >= 100000) return '₹ ${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹ ${(v / 1000).toStringAsFixed(1)}K';
    return '₹ ${v.toStringAsFixed(0)}';
  }

  static List<CategoryBreakdownItemDto> _fallbackCategories() {
    return const [
      CategoryBreakdownItemDto(category: 'IMFL Spirits', amount: 54000),
      CategoryBreakdownItemDto(category: 'Beer & Cider', amount: 28500),
      CategoryBreakdownItemDto(category: 'Country Liquor', amount: 16800),
    ];
  }
}
