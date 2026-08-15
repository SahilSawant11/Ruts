import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/data/info_list_tile.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/dashboard_providers.dart';

class TopCustomersCard extends ConsumerWidget {
  const TopCustomersCard({super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Top Customers', subtitle: 'Last 30 days'),
          const SizedBox(height: 4),
          summaryAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'Could not load customers.',
                  style: AppTypography.bodyMuted.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
            ),
            data: (summary) {
              if (summary.topCustomers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'No named customers yet — most bills are Counter Sale.',
                      style: AppTypography.bodyMuted.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final c in summary.topCustomers)
                    InfoListTile(
                      avatarText: _initials(c.customerName),
                      title: c.customerName,
                      subtitle: '${c.billCount} bill${c.billCount == 1 ? '' : 's'}',
                      trailing: '₹${c.totalAmount.toStringAsFixed(0)}',
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
