import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/dashboard_providers.dart';

/// 'Overall Information' Card matching the mood board:
///  3 quick horizontal summary action tiles with count, label, and chevron button:
///   1. Suppliers  (Dark filled card)
///   2. SCM Catalog Codes (Light card)
///   3. Total Orders / Bills (Light card)
class OverallInformationCard extends ConsumerWidget {
  const OverallInformationCard({super.key});

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
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.chartBlue.withValues(alpha: 0.20)
                      : AppColors.chartBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.chartBlue,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Overall Information',
                style: AppTypography.sectionTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Summary Action Tiles
          summaryAsync.when(
            loading: () => const SizedBox(
              height: 72,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox(
              height: 72,
              child: Center(child: Text('—')),
            ),
            data: (summary) {
              final suppliers = summary.supplierCount;
              final catalogItems = summary.materialCount;
              final lowStock = summary.lowStockCount;

              return Row(
                children: [
                  // Tile 1: Suppliers (Dark filled card matching mood board) -> routes to /supplier
                  Expanded(
                    child: _InfoTile(
                      count: '$suppliers',
                      label: 'Suppliers',
                      icon: Icons.store_outlined,
                      isPrimaryDark: true,
                      onTap: () => context.go('/supplier'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Tile 2: SCM Catalog Codes -> routes to /inventory
                  Expanded(
                    child: _InfoTile(
                      count: '$catalogItems',
                      label: 'SCM Codes',
                      icon: Icons.qr_code_2_rounded,
                      isPrimaryDark: false,
                      onTap: () => context.go('/inventory'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Tile 3: Low Stock Alerts -> routes to /inventory
                  Expanded(
                    child: _InfoTile(
                      count: '$lowStock',
                      label: 'Low Stock',
                      icon: Icons.warning_amber_rounded,
                      isPrimaryDark: false,
                      onTap: () => context.go('/inventory'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.count,
    required this.label,
    required this.icon,
    required this.isPrimaryDark,
    required this.onTap,
  });

  final String count;
  final String label;
  final IconData icon;
  final bool isPrimaryDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    // Dark tile background matching mood board #16161F or light tile
    final bgColor = isPrimaryDark
        ? (isDark ? const Color(0xFF1B1E28) : const Color(0xFF161820))
        : AppColors.surfaceFor(context);
    final textColor = isPrimaryDark ? Colors.white : AppColors.textPrimaryFor(context);
    final subColor = isPrimaryDark
        ? Colors.white.withValues(alpha: 0.70)
        : AppColors.textSecondaryFor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isPrimaryDark
                  ? Colors.transparent
                  : AppColors.borderFor(context),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Count & Label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      count,
                      style: AppTypography.h2.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 12, color: subColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: subColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // Circular Chevron Button
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isPrimaryDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : (isDark
                          ? Colors.white10
                          : AppColors.backgroundFor(context)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 15,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
