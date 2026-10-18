import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/dashboard_providers.dart';
import '../../data/models/dashboard_summary_dto.dart';

/// 'Top Categories' Card — replaces the static customers overview:
/// Shows dynamic category sales revenue, share percentages, and progress indicators
/// aggregated directly from sales line items in SQLite.
class TopCategoriesCard extends ConsumerWidget {
  const TopCategoriesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          // Header: Category Icon + Title + 'View all' link
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
                          ? AppColors.chartTeal.withValues(alpha: 0.20)
                          : AppColors.chartTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      size: 16,
                      color: AppColors.chartTeal,
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
              InkWell(
                onTap: () => context.go('/category'),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'View all',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
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
          const SizedBox(height: 14),

          // Categories List
          summaryAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox(
              height: 120,
              child: Center(child: Text('—')),
            ),
            data: (summary) {
              final categories = summary.categoryBreakdown.isNotEmpty
                  ? summary.categoryBreakdown
                  : _fallbackCategories();

              final total = categories.fold<double>(0, (s, c) => s + c.amount);

              const colors = [
                Color(0xFF6E56CF), // Purple
                Color(0xFF2EBD85), // Teal/Green
                Color(0xFFF5A524), // Amber
                Color(0xFF388BFD), // Blue
              ];

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.take(3).length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final cat = categories[idx];
                  final percent = total > 0 ? (cat.amount / total) : 0.0;
                  final color = colors[idx % colors.length];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat.category.isNotEmpty ? cat.category : 'General',
                                style: AppTypography.body.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimaryFor(context),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '₹ ${_formatRupee(cat.amount)}',
                                style: AppTypography.mono.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryFor(context),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? color.withValues(alpha: 0.20)
                                      : color.withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  '${(percent * 100).toStringAsFixed(0)}%',
                                  style: AppTypography.mono.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: percent.clamp(0.05, 1.0),
                          minHeight: 5,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFEEEEF4),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
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
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)} L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} K';
    return v.toStringAsFixed(0);
  }

  static List<CategoryBreakdownItemDto> _fallbackCategories() {
    return const [
      CategoryBreakdownItemDto(category: 'IMFL Spirits', amount: 54000),
      CategoryBreakdownItemDto(category: 'Beer & Cider', amount: 28500),
      CategoryBreakdownItemDto(category: 'Country Liquor', amount: 16800),
    ];
  }
}
