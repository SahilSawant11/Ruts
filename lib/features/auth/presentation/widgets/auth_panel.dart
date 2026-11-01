import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Centered card used by the activation and change-password screens so
/// they share one look with the login screen.
class AuthPanel extends StatelessWidget {
  const AuthPanel({super.key, required this.title, required this.subtitle, required this.children, this.icon});

  final String title;
  final String subtitle;
  final AppIconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.fromLTRB(34, 34, 34, 30),
              decoration: BoxDecoration(
                color: AppColors.surfaceFor(context),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.borderFor(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoftFor(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: AppIcon(icon!, size: 24, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(title, style: AppTypography.h1.copyWith(fontSize: 28, height: 1.1)),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: AppTypography.body.copyWith(height: 1.5, color: AppColors.textSecondaryFor(context)),
                  ),
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(message!, style: AppTypography.caption.copyWith(color: AppColors.danger)),
    );
  }
}
