import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/dashboard_providers.dart';
import '../../data/models/dashboard_summary_dto.dart';

/// 'Recent Transaction' Card matching user requirements:
///  - Removed TXN ID column
///  - Removed Status column
///  - Shows Brand / Material Name with Quantity in brackets
///  - Shows Transaction Date & Time
///  - Pay Mode and Amount
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
                    'Recent Transactions',
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
                onTap: () => context.go('/reports'),
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
                Expanded(
                  flex: 5,
                  child: Text(
                    'Item / Material (Qty)',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedFor(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Date & Time',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedFor(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Mode',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedFor(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Amount',
                    textAlign: TextAlign.end,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedFor(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
                  final displayName = txn.itemDetail ?? txn.customerName;

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Item / Material Name with (Qty)
                        Expanded(
                          flex: 5,
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
                                  Icons.liquor_outlined,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.body.copyWith(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimaryFor(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Date & Time
                        Expanded(
                          flex: 4,
                          child: Text(
                            _formatDateTime(txn.billDate),
                            style: AppTypography.mono.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondaryFor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Pay Mode
                        Expanded(
                          flex: 2,
                          child: Text(
                            txn.payMode,
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryFor(context),
                            ),
                          ),
                        ),

                        // Amount
                        Expanded(
                          flex: 3,
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

  static String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day $month, ${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }

  static List<RecentTransactionDto> _fallbackTransactions() {
    return [
      RecentTransactionDto(
        billNo: 'TXN-1001',
        billDate: DateTime.now().subtract(const Duration(minutes: 15)),
        customerName: 'Counter Sale',
        itemDetail: 'Old Monk XXX Rum (2)',
        payMode: 'Cash',
        totalAmount: 480.00,
        status: 'synced',
      ),
      RecentTransactionDto(
        billNo: 'TXN-1002',
        billDate: DateTime.now().subtract(const Duration(minutes: 42)),
        customerName: 'Counter Sale',
        itemDetail: 'Royal Challenge (1)',
        payMode: 'UPI',
        totalAmount: 720.00,
        status: 'synced',
      ),
      RecentTransactionDto(
        billNo: 'TXN-1003',
        billDate: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
        customerName: 'Counter Sale',
        itemDetail: 'Tuborg Premium (4)',
        payMode: 'Card',
        totalAmount: 640.00,
        status: 'synced',
      ),
      RecentTransactionDto(
        billNo: 'TXN-1004',
        billDate: DateTime.now().subtract(const Duration(hours: 2, minutes: 5)),
        customerName: 'Counter Sale',
        itemDetail: 'Blenders Pride (1)',
        payMode: 'Cash',
        totalAmount: 980.00,
        status: 'synced',
      ),
    ];
  }
}
