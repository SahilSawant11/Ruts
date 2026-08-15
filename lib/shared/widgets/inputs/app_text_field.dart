import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
    this.selectAllOnFocus = false,
    this.showPasteButton = false,
    this.obscureText = false,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool enabled;
  final Widget? suffix;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final bool selectAllOnFocus;
  final bool showPasteButton;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: AppTypography.label),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: textInputAction,
          obscureText: obscureText,
          enableInteractiveSelection: true,
          onTap: selectAllOnFocus && controller != null
              ? () => controller!.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: controller!.text.length,
                  )
              : null,
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimaryFor(context),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMuted.copyWith(
              color: AppColors.textMutedFor(context),
            ),
            isDense: true,
            suffixIcon: _buildSuffix(context),
            filled: true,
            fillColor: enabled
                ? AppColors.surfaceFor(context)
                : AppColors.surfaceAltFor(context),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.borderFor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.borderFor(context)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.borderFor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffix(BuildContext context) {
    final pasteButton = showPasteButton && controller != null && enabled && !readOnly
        ? IconButton(
            tooltip: 'Paste',
            onPressed: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              final text = data?.text;
              if (text == null || text.isEmpty) return;
              controller!
                ..text = text
                ..selection = TextSelection.collapsed(offset: text.length);
              onChanged?.call(text);
            },
            icon: Icon(
              Icons.content_paste_rounded,
              size: 18,
              color: AppColors.textSecondaryFor(context),
            ),
          )
        : null;

    if (suffix == null) return pasteButton;
    if (pasteButton == null) return suffix;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        pasteButton,
        suffix!,
      ],
    );
  }
}
