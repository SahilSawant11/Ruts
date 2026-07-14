import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class ReportFiltersCard extends StatelessWidget {
  const ReportFiltersCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Filters'),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(child: AppTextField(label: 'DATE', hint: '28-Jun-2026')),
              const SizedBox(width: AppSpacing.md),
              const Expanded(child: AppTextField(label: 'REGISTER / COUNTER', hint: 'Main Counter')),
              const SizedBox(width: AppSpacing.md),
              const Expanded(child: AppTextField(label: 'TRANSACTION TYPE', hint: 'Sales')),
              const SizedBox(width: AppSpacing.md),
              const Expanded(child: AppTextField(label: 'PAY MODE', hint: 'All')),
              const SizedBox(width: AppSpacing.md),
              PrimaryButton(label: 'Generate', icon: Icons.search_rounded, onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}
