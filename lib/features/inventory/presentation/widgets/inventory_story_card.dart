import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/inventory_providers.dart';

class InventoryStoryCard extends ConsumerWidget {
  const InventoryStoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(filteredInventoryOverviewProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: inventoryAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (error, _) => Center(
          child: Text(
            'Could not load inventory summary: $error',
            style: AppTypography.bodyMuted.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
        ),
        data: (items) {
          final ready = items.where((item) => item.isInStock).length;
          final low = items.where((item) => item.isLowStock).length;
          final out = items.where((item) => item.isOutOfStock).length;

          final bottleCount = items.where((item) => !item.packing.toLowerCase().contains('can')).length;
          final canCount = items.where((item) => item.packing.toLowerCase().contains('can')).length;
          final totalUnits = items.fold<int>(0, (sum, item) => sum + item.qtyOnHand);

          final categoryCounts = <String, int>{};
          for (final item in items) {
            categoryCounts[item.category] = (categoryCounts[item.category] ?? 0) + 1;
          }
          final topCategory = categoryCounts.entries.isEmpty
              ? null
              : (categoryCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Inventory Story',
                subtitle: 'The fastest read of your floor right now',
                trailing: _summaryBadge(context, '${items.length} tracked items'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.isDark(context)
                              ? [
                                  AppColors.surfaceAltDark,
                                  const Color(0xFF23283A),
                                ]
                              : [
                                  const Color(0xFFF5F2FF),
                                  Colors.white,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.borderFor(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ready == 0 ? 'Shelf needs attention' : '$ready items are shelf-ready',
                            style: AppTypography.h2.copyWith(
                              color: AppColors.textPrimaryFor(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalUnits total units on hand across bottles and cans.',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondaryFor(context),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              _toneChip(context, 'Ready', '$ready', AppColors.success, AppColors.successSoft),
                              _toneChip(context, 'Low', '$low', AppColors.warning, AppColors.warningSoft),
                              _toneChip(context, 'Out', '$out', AppColors.danger, AppColors.dangerSoft),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      children: [
                        _miniMetric(context, 'Bottles', '$bottleCount', Icons.local_bar_rounded),
                        const SizedBox(height: AppSpacing.md),
                        _miniMetric(context, 'Cans', '$canCount', Icons.local_drink_rounded),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _insightPanel(
                      context,
                      title: 'Format Mix',
                      subtitle: 'Quick visual split of what you are carrying',
                      children: [
                        _mixBar(context, label: 'Bottles', count: bottleCount, total: items.length, color: AppColors.primary),
                        const SizedBox(height: 10),
                        _mixBar(context, label: 'Cans', count: canCount, total: items.length, color: AppColors.chartBlue),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: _insightPanel(
                      context,
                      title: 'Main Category',
                      subtitle: 'Where the catalog is currently heaviest',
                      children: [
                        Text(
                          topCategory?.key ?? 'No category data',
                          style: AppTypography.h2.copyWith(
                            color: AppColors.textPrimaryFor(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          topCategory == null
                              ? 'Import or create materials to see the category story.'
                              : '${topCategory.value} items are currently grouped under this category.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondaryFor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryBadge(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondaryFor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _miniMetric(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodyMuted.copyWith(color: AppColors.textSecondaryFor(context))),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.h2.copyWith(color: AppColors.textPrimaryFor(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightPanel(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.sectionTitle.copyWith(color: AppColors.textPrimaryFor(context))),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTypography.bodyMuted.copyWith(color: AppColors.textSecondaryFor(context))),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }

  Widget _mixBar(
    BuildContext context, {
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTypography.body.copyWith(color: AppColors.textPrimaryFor(context), fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('$count', style: AppTypography.body.copyWith(color: AppColors.textSecondaryFor(context))),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            backgroundColor: AppColors.surfaceAltFor(context),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _toneChip(BuildContext context, String label, String value, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label $value',
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
