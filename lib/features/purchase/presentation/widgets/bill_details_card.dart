import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';

/// "Bill Details" panel: distributor, dates, challan/note numbers, pay
/// mode, transport particulars. Dummy values only.
class BillDetailsCard extends StatelessWidget {
  const BillDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Bill Details', subtitle: 'Inward / GRN entry'),
          const SizedBox(height: AppSpacing.md),
          _row(const [
            AppTextField(label: 'BILL NO.', hint: '—'),
            AppTextField(label: 'DISTRIBUTORS *', hint: 'J.R.TOLARAM — Mumbai'),
            AppTextField(label: 'DATE', hint: '28-Jun-2026'),
          ], flexes: [2, 5, 2]),
          const SizedBox(height: AppSpacing.md),
          _row(const [
            AppTextField(label: 'CHALLAN NO.', hint: 'CHL-88142'),
            AppTextField(label: 'NOTE NO.', hint: '—'),
            AppTextField(label: 'PAY MODE', hint: 'Credit'),
          ]),
          const SizedBox(height: AppSpacing.md),
          _row(const [
            AppTextField(label: 'TP NO.', hint: 'TP-2026-0091'),
            AppTextField(label: 'TP DATE', hint: '28-Jun-2026'),
            AppTextField(label: 'ST NO.', hint: 'ST-MH07'),
          ]),
        ],
      ),
    );
  }

  Widget _row(List<Widget> fields, {List<int>? flexes}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(flex: flexes?[i] ?? 1, child: fields[i]),
        ],
      ],
    );
  }
}
