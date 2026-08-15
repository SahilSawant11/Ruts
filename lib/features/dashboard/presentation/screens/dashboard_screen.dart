import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../inventory/data/inventory_providers.dart';
import '../../../sales/data/sales_providers.dart';
import '../../data/dashboard_providers.dart';
import '../widgets/category_sales_card.dart';
import '../widgets/daily_target_card.dart';
import '../widgets/kpi_row.dart';
import '../widgets/payment_mix_card.dart';
import '../widgets/recent_transactions_card.dart';
import '../widgets/sales_trend_card.dart';
import '../widgets/stock_alerts_card.dart';
import '../widgets/top_customers_card.dart';
import '../widgets/top_selling_items_card.dart';

/// Widget tree:
/// AppShell
///   └── DashboardScreen body
///         └── SingleChildScrollView → Column
///               ├── _DashboardHeader (title + real date + Refresh)
///               ├── DashboardKpiRow (4 KPI cards, real data)
///               ├── Row: SalesTrendCard | CategorySalesCard
///               ├── Row: PaymentMixCard | DailyTargetCard
///               ├── Row: TopSellingItemsCard | RecentTransactionsCard
///               ├── TopCustomersCard
///               └── StockAlertsCard
///
/// All widgets read from dashboardSummaryProvider (one API call) or
/// inventoryOverviewProvider (shared with the Inventory screen).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardHeader(),
          SizedBox(height: AppSpacing.md),
          DashboardKpiRow(),
          SizedBox(height: AppSpacing.lg),
          _TwoColumn(left: SalesTrendCard(), right: CategorySalesCard()),
          _TwoColumn(left: PaymentMixCard(), right: DailyTargetCard()),
          _TwoColumn(left: TopSellingItemsCard(), right: RecentTransactionsCard()),
          TopCustomersCard(),
          SizedBox(height: AppSpacing.lg),
          StockAlertsCard(),
        ],
      ),
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader();

  String _formatToday() {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year} (${weekdays[now.weekday - 1]})';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingSyncAsync = ref.watch(pendingSalesSyncCountProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: AppTypography.h1.copyWith(
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Store performance at a glance — ${_formatToday()}.',
                style: AppTypography.bodyMuted.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ),
        pendingSyncAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (count) => count > 0
              ? const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: StatusChip(label: 'Queued offline', tone: StatusChipTone.neutral),
                )
              : const SizedBox.shrink(),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.backgroundFor(context),
            border: Border.all(color: AppColors.borderFor(context)),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Today',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.unfold_more_rounded,
                size: 16,
                color: AppColors.textSecondaryFor(context),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SecondaryButton(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          dense: true,
          onPressed: () {
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(inventoryOverviewProvider);
          },
        ),
      ],
    );
  }
}

/// Two cards side by side with a fixed gutter, stacked below `_DashboardHeader`.
class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: right),
        ],
      ),
    );
  }
}
