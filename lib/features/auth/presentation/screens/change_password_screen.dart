import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/auth/auth_repository.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../widgets/auth_panel.dart';

/// Shown after sign-in when the account still has a default or
/// owner-assigned temporary password.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _nextFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_current, _next, _confirm]) {
      c.dispose();
    }
    _nextFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_next.text != _confirm.text) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref
        .read(authControllerProvider.notifier)
        .changePassword(currentPassword: _current.text, newPassword: _next.text);
    if (!mounted) return;
    if (error != null) setState(() => _error = error);
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return AuthPanel(
      icon: AppIcons.lock,
      title: 'Set a new password',
      subtitle: 'Hi ${user?.displayName ?? ''}, please replace the temporary password before continuing. '
          'Use at least ${AuthRepository.minPasswordLength} characters.',
      children: [
        AppTextField(
          label: 'CURRENT PASSWORD',
          controller: _current,
          obscureText: true,
          autofocus: true,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _nextFocus.requestFocus(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'NEW PASSWORD',
          controller: _next,
          focusNode: _nextFocus,
          obscureText: true,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _confirmFocus.requestFocus(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'CONFIRM NEW PASSWORD',
          controller: _confirm,
          focusNode: _confirmFocus,
          obscureText: true,
          onSubmitted: (_) => _submit(),
        ),
        AuthErrorText(_error),
        const SizedBox(height: 20),
        PrimaryButton(
          label: _busy ? 'Saving…' : 'Save password',
          icon: AppIcons.check,
          expand: true,
          onPressed: _busy ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: 'Sign out',
          icon: AppIcons.logout,
          expand: true,
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
      ],
    );
  }
}
