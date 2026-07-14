import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

enum ReportTab { dayWise, monthly, custom }

class ReportTabs extends StatelessWidget {
  const ReportTabs({super.key, required this.selected, required this.onChanged});

  final ReportTab selected;
  final ValueChanged<ReportTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(ReportTab.dayWise, 'Day-wise', Icons.calendar_today_outlined),
          _segment(ReportTab.monthly, 'Monthly', Icons.calendar_month_outlined),
          _segment(ReportTab.custom, 'Custom', Icons.filter_list_rounded),
        ],
      ),
    );
  }

  Widget _segment(ReportTab tab, String label, IconData icon) {
    final isSelected = tab == selected;
    return Material(
      color: isSelected ? AppColors.background : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      elevation: isSelected ? 1 : 0,
      child: InkWell(
        onTap: () => onChanged(tab),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: isSelected ? AppColors.primary : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
