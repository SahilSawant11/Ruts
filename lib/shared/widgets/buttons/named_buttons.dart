import 'package:flutter/material.dart';
import 'app_button.dart';

/// These thin wrappers exist purely so call-sites read naturally
/// (PrimaryButton, DangerButton, ...) while AppButton stays the single
/// source of truth for padding/radius/typography.

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.shortcut,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? shortcut;
  final bool expand;

  @override
  Widget build(BuildContext context) => AppButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        shortcut: shortcut,
        expand: expand,
        variant: AppButtonVariant.primary,
      );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.shortcut,
    this.expand = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? shortcut;
  final bool expand;
  final bool dense;

  @override
  Widget build(BuildContext context) => AppButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        shortcut: shortcut,
        expand: expand,
        dense: dense,
        variant: AppButtonVariant.secondary,
      );
}

class SuccessButton extends StatelessWidget {
  const SuccessButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.shortcut,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? shortcut;
  final bool expand;

  @override
  Widget build(BuildContext context) => AppButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        shortcut: shortcut,
        expand: expand,
        variant: AppButtonVariant.success,
      );
}

class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.shortcut,
    this.expand = false,
    this.outline = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? shortcut;
  final bool expand;
  final bool outline;

  @override
  Widget build(BuildContext context) => AppButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        shortcut: shortcut,
        expand: expand,
        variant: outline ? AppButtonVariant.dangerOutline : AppButtonVariant.danger,
      );
}
