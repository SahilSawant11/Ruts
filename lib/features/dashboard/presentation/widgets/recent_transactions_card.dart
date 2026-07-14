import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/tag_pill.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({super.key});

  static const _rows = [
    ('223118', '14:52', 'Counter Sale', '₹1,350', TagPillTone.success, 'Paid'),
    ('223117', '14:48', 'Walk-in Credit', '₹2,040', TagPillTone.amber, 'Credit'),
    ('223116', '14:41', 'Counter Sale', '₹680', TagPillTone.success, 'Paid'),
    ('223115', '14:35', 'CounterSale.Sale', '₹3,402', TagPillTone.success, 'Paid'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Recent Transactions',
            subtitle: 'Live',
            trailing: SecondaryButton(label: 'View all', onPressed: () {}, dense: true),
          ),
          const SizedBox(height: AppSpacing.sm),
          _headerRow(),
          const Divider(height: 1, color: AppColors.border),
          for (final row in _rows) _dataRow(row),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('BILL', style: AppTypography.label)),
          Expanded(flex: 2, child: Text('TIME', style: AppTypography.label)),
          Expanded(flex: 3, child: Text('CUSTOMER', style: AppTypography.label)),
          Expanded(flex: 2, child: Text('AMOUNT', style: AppTypography.label, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('STATUS', style: AppTypography.label)),
        ],
      ),
    );
  }

  Widget _dataRow((String, String, String, String, TagPillTone, String) row) {
    final (bill, time, customer, amount, tone, status) = row;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(bill, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text(time, style: AppTypography.bodyMuted)),
          Expanded(flex: 3, child: Text(customer, style: AppTypography.body, overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 2,
            child: Text(amount, textAlign: TextAlign.right, style: AppTypography.mono.copyWith(fontSize: 12.5)),
          ),
          Expanded(flex: 2, child: TagPill(label: status, tone: tone)),
        ],
      ),
    );
  }
}
