import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin123');
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await ref.read(authControllerProvider.notifier).signIn(
          username: _usernameController.text,
          password: _passwordController.text,
        );

    if (!mounted || success) return;
    final message = ref.read(authControllerProvider).errorMessage ?? 'Login failed.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundFor(context),
              AppColors.primarySoft,
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_bar_rounded,
                              color: AppColors.primary,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text('Caskly', style: AppTypography.h1.copyWith(fontSize: 42)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Offline-first liquor store POS built for fast billing, local reliability, and smoother store operations.',
                            style: AppTypography.body.copyWith(
                              fontSize: 16,
                              height: 1.5,
                              color: AppColors.textSecondaryFor(context),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _credentialHint(context),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundFor(context),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderFor(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sign in', style: AppTypography.h1.copyWith(fontSize: 30)),
                          const SizedBox(height: 6),
                          Text(
                            'Use a local account to open the store workspace.',
                            style: AppTypography.bodyMuted.copyWith(
                              color: AppColors.textSecondaryFor(context),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppTextField(
                            label: 'USERNAME',
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                            showPasteButton: true,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'PASSWORD',
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            textInputAction: TextInputAction.done,
                            obscureText: true,
                            onSubmitted: (_) => _submit(),
                            showPasteButton: true,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          PrimaryButton(
                            label: auth.isLoading ? 'Signing in…' : 'Enter Caskly',
                            icon: Icons.login_rounded,
                            expand: true,
                            onPressed: auth.isLoading ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _credentialHint(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Starter accounts', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          Text('admin / admin123', style: AppTypography.mono.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('owner / owner123', style: AppTypography.mono.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('cashier / cash123', style: AppTypography.mono.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
