
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/caskly_logo.dart';
import '../widgets/martini_glass.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Prefill only in debug builds, for development convenience.
  final _usernameController = TextEditingController(text: kDebugMode ? 'admin' : '');
  final _passwordController = TextEditingController(text: kDebugMode ? 'admin123' : '');
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
      body: LayoutBuilder(builder: (context, constraints) {
        // Wide windows: the 3D martini on the left, sign-in on the right.
        // Small windows (or very short ones) get the form alone.
        final showGlass = constraints.maxWidth >= 880 && constraints.maxHeight >= 520;
        final form = _form(context, auth.isLoading, showLogo: !showGlass);
        if (!showGlass) return Center(child: form);
        return Row(
          children: [
            Expanded(flex: 46, child: _glassPanel(context)),
            Expanded(flex: 54, child: Center(child: form)),
          ],
        );
      }),
    );
  }

  Widget _glassPanel(BuildContext context) {
    const cream = Color(0xFFF3EFE6);
    return ColoredBox(
      color: const Color(0xFF141218),
      child: Stack(
        children: [
          const Positioned.fill(child: MartiniGlass()),
          Positioned(
            left: 40,
            right: 40,
            bottom: 34,
            child: IgnorePointer(
              child: Row(
                children: [
                  Text(
                    'C A S K L Y',
                    style: AppTypography.label.copyWith(color: cream, fontSize: 12, letterSpacing: 2),
                  ),
                  const Spacer(),
                  Text(
                    'Built for the bottle counter.',
                    style: AppTypography.caption.copyWith(color: cream.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(BuildContext context, bool loading, {required bool showLogo}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLogo) ...[
              const CasklyLogo(size: 60),
              const SizedBox(height: 28),
            ],
            Text(
              'Welcome back',
              style: AppTypography.h1.copyWith(fontSize: 34, height: 1.05, letterSpacing: -0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to continue to your store.',
              style: AppTypography.body.copyWith(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textSecondaryFor(context),
              ),
            ),
            const SizedBox(height: 32),
            AppTextField(
              label: 'USERNAME',
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'PASSWORD',
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              textInputAction: TextInputAction.done,
              obscureText: true,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: loading ? 'Signing in…' : 'Enter Caskly',
              icon: AppIcons.arrowForward,
              expand: true,
              onPressed: loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
