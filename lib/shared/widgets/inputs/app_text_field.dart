import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Label-on-top text field used for every form field in the app
/// (Invoice Details, Payment amount, etc). Keeps label style,
/// field height and radius consistent everywhere.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.enabled = true,
    this.suffix,
    this.readOnly = false,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool enabled;
  final Widget? suffix;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          style: AppTypography.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMuted,
            isDense: true,
            suffixIcon: suffix,
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.surfaceAlt,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
