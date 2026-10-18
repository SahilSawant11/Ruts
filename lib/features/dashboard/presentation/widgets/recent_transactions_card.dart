import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/dashboard_providers.dart';
import '../../data/models/dashboard_summary_dto.dart';

/// 'Recent Transaction' Card matching the mood board:
///  - Header with amber receipt icon & filter button
///  - Table columns: Checkbox · ID Transaction · Product / Detail · Status Pill · Amount
class RecentTransactionsCard extends ConsumerWidget {
  const RecentTransactionsCard({super.key});

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
          // Header: Amber Receipt Icon + Title + Filter Action
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
                          ? AppColors.chartAmber.withValues(alpha: 0.20)
                          : const Color(0xFFFEF3E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      size: 16,
                      color: AppColors.chartAmber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Recent Transaction',
                    style: AppTypography.sectionTitle.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimaryFor(context),
                    ),
                  ),
                ],
              ),

              // Filter Icon Button
              InkWell(
                onTap: () => context.go('/reports/brandwise'),
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceFor(context),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderFor(context)),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 15,
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mini Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                // Selection Circle Placeholder
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.borderFor(context),
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ID Transaction',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedFor(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Product / Detail',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedFor(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Status',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMutedFor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Amount',
                    textAlign: TextAlign.end,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedFor(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderFor(context),
          ),

          // Transaction Rows
          summaryAsync.when(
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox(
              height: 160,
              child: Center(child: Text('—')),
            ),
            data: (summary) {
              final txns = summary.recentTransactions.isNotEmpty
                  ? summary.recentTransactions
                  : _fallbackTransactions();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: txns.length.clamp(0, 4),
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderFor(context),
                ),
                itemBuilder: (context, index) {
                  final txn = txns[index];
                  final isPending = index == 1;

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Checkbox circle
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.borderFor(context),
                              width: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // ID Transaction
                        Expanded(
                          flex: 2,
                          child: Text(
                            txn.billNo,
                            style: AppTypography.mono.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryFor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Product / Customer Detail
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF232734)
                                      : const Color(0xFFF1F1F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.receipt_outlined,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  txn.customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.body.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimaryFor(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status Pill (Solid Green for Success, Solid Orange for Pending)
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPending
                                    ? const Color(0xFFF5A524)
                                    : const Color(0xFF2EBD85),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                isPending ? 'Pending' : 'Success',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Amount
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹ ${txn.totalAmount.toStringAsFixed(2)}',
                            textAlign: TextAlign.end,
                            style: AppTypography.mono.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryFor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  static List<RecentTransactionDto> _fallbackTransactions() {
    return [
      RecentTransactionDto(
        billNo: '476-893',
        billDate: DateTime.now(),
        customerName: 'Premium T-Shirt',
        payMode: 'Cash',
        totalAmount: 24.51,
        status: 'synced',
      ),
      RecentTransactionDto(
        billNo: '476-894',
        billDate: DateTime.now(),
        customerName: 'KitchenAid Mixer',
        payMode: 'UPI',
        totalAmount: 24.51,
        status: 'pending',
      ),
      RecentTransactionDto(
        billNo: '476-895',
        billDate: DateTime.now(),
        customerName: 'Apple AirPods 2',
        payMode: 'Card',
        totalAmount: 85.00,
        status: 'synced',
      ),
    ];
  }
}
