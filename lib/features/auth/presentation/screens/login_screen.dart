import 'dart:ui';

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
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: Stack(
        children: [
          _background(context, isDark),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(34, 34, 34, 30),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF181B23).withValues(alpha: 0.92)
                            : Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.white.withValues(alpha: 0.96),
                        ),
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
                          _brandMark(context, isDark),
                          const SizedBox(height: 28),
                          Text(
                            'Welcome back',
                            style: AppTypography.h1.copyWith(
                              fontSize: 34,
                              height: 1.05,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue to your store workspace.',
                            style: AppTypography.body.copyWith(
                              fontSize: 15,
                              height: 1.5,
                              color: AppColors.textSecondaryFor(context),
                            ),
                          ),
                          const SizedBox(height: 26),
                          _fieldShell(
                            context,
                            child: AppTextField(
                              label: 'USERNAME',
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _fieldShell(
                            context,
                            child: AppTextField(
                              label: 'PASSWORD',
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              textInputAction: TextInputAction.done,
                              obscureText: true,
                              onSubmitted: (_) => _submit(),
                            ),
                          ),
                          const SizedBox(height: 22),
                          PrimaryButton(
                            label: auth.isLoading ? 'Signing in…' : 'Enter Caskly',
                            icon: Icons.arrow_forward_rounded,
                            expand: true,
                            onPressed: auth.isLoading ? null : _submit,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Default login: admin / admin123',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryFor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _background(BuildContext context, bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF11141B),
                      const Color(0xFF161922),
                      const Color(0xFF1B1F2A),
                    ]
                  : [
                      const Color(0xFFF8F8F6),
                      const Color(0xFFF3F2EE),
                      const Color(0xFFFAFAF8),
                    ],
            ),
          ),
        ),
        Positioned(
          top: -140,
          right: -120,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: -140,
          bottom: -140,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFE7DDD0).withValues(alpha: isDark ? 0.07 : 0.32),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _BackdropGridPainter(
              lineColor: isDark
                  ? Colors.white.withValues(alpha: 0.018)
                  : const Color(0xFFDBD7CF).withValues(alpha: 0.24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _brandMark(BuildContext context, bool isDark) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE9E3DA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.wine_bar_rounded,
        color: AppColors.primary,
        size: 30,
      ),
    );
  }

  Widget _fieldShell(
    BuildContext context, {
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundFor(context).withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.isDark(context)
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFEAE6DF),
        ),
      ),
      child: child,
    );
  }
}

class _BackdropGridPainter extends CustomPainter {
  const _BackdropGridPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    const gap = 88.0;

    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
