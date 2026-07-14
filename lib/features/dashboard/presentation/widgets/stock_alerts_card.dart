import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class StockAlertsCard extends StatelessWidget {
  const StockAlertsCard({super.key});

  static const _alerts = [
    ('Royal Stag Classic Whisky', '750ml · reorder at 50', '12', true),
    ("McDowell's No.1 Rum", '750ml · reorder at 40', '31', false),
    ('Absolut Vodka', '700ml · reorder at 25', '6', true),
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Stock Alerts',
            subtitle: 'Below reorder level',
            trailing: SecondaryButton(
              label: 'Open Stock',
              dense: true,
              onPressed: () => context.go('/inventory'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final alert in _alerts) _alertRow(alert),
        ],
      ),
    );
  }

  Widget _alertRow((String, String, String, bool) alert) {
    final (name, meta, stock, severe) = alert;
    final color = severe ? AppColors.danger : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 17, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(name, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Expanded(child: Text(' · $meta', style: AppTypography.caption)),
          Text(stock, style: AppTypography.mono.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
