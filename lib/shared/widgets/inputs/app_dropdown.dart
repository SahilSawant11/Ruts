import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Label-on-top dropdown, styled to match [AppTextField] so form grids
/// can mix text fields and selects without looking inconsistent.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    this.value,
    this.hint,
    this.onChanged,
  });

  final String label;
  final List<T> items;
  final String Function(T) itemLabel;
  final T? value;
  final String? hint;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              hint: hint != null ? Text(hint!, style: AppTypography.bodyMuted) : null,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMuted),
              style: AppTypography.body,
              items: items
                  .map((item) => DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
