import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/licensing/license_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../widgets/auth_panel.dart';

/// Shown when this computer has no valid license. The store reads out or
/// copies its Machine ID; the vendor replies with a license key.
class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key, required this.status});

  final LicenseStatus status;

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _keyController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.status.state != LicenseState.missing) _error = widget.status.message;
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Paste the license key you received.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(licenseServiceProvider).activate(key);
    if (!mounted) return;
    if (result.state == LicenseState.valid) {
      ref.invalidate(licenseStatusProvider);
    } else {
      setState(() {
        _busy = false;
        _error = result.message ?? 'Activation failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final machineId = widget.status.machineId;
    return AuthPanel(
      icon: AppIcons.lock,
      title: widget.status.state == LicenseState.expired ? 'License expired' : 'Activate Caskly',
      subtitle: 'Send this computer\'s Machine ID to your Caskly provider. '
          'They will give you a license key for this computer.',
      children: [
        Text('MACHINE ID', style: AppTypography.label.copyWith(color: AppColors.textSecondaryFor(context))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAltFor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderFor(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  machineId,
                  style: AppTypography.mono.copyWith(fontSize: 18, letterSpacing: 1.5, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                icon: const AppIcon(AppIcons.paste, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: machineId));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Machine ID copied')));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'LICENSE KEY',
          hint: 'CASKLY1.…',
          controller: _keyController,
          autofocus: true,
          showPasteButton: true,
          onSubmitted: (_) => _activate(),
        ),
        AuthErrorText(_error),
        const SizedBox(height: 20),
        PrimaryButton(
          label: _busy ? 'Activating…' : 'Activate',
          icon: AppIcons.lockOpen,
          expand: true,
          onPressed: _busy ? null : _activate,
        ),
      ],
    );
  }
}
