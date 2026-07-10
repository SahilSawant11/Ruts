import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';

/// "Invoice Details" panel: bill number, customer, type, date, pay
/// mode, license fields and running balance. Dummy values only for now.
class InvoiceDetailsCard extends StatelessWidget {
  const InvoiceDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Invoice Details',
            subtitle: 'Auto-numbered counter sale',
          ),
          const SizedBox(height: AppSpacing.md),
          _row(const [
            AppTextField(label: 'BILL NO.', hint: '223115'),
            AppTextField(label: 'CUSTOMER', hint: 'CounterSale.Sale'),
            AppTextField(label: 'TYPE', hint: 'CounterSale.Sale'),
            AppTextField(label: 'DATE', hint: '28-Jun-2026'),
            AppTextField(label: 'PAY MODE', hint: 'Cash'),
          ]),
          const SizedBox(height: AppSpacing.md),
          _row(const [
            AppTextField(label: 'LICENSE NO.', hint: 'Life Time'),
            AppTextField(label: 'LICENSE NAME', hint: 'J.R.TOLARAM'),
            AppTextField(label: 'VALIDITY', hint: '24-Mar-2017'),
            AppTextField(label: 'BALANCE', hint: '0.00'),
          ]),
        ],
      ),
    );
  }

  Widget _row(List<Widget> fields) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(child: fields[i]),
        ],
      ],
    );
  }
}
