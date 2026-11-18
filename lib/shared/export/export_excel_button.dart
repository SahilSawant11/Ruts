import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';

/// Icon button that runs [onExport] and reports where the file was saved.
/// Disabled while [onExport] is null (e.g. list still loading or empty).
class ExportExcelButton extends StatefulWidget {
  const ExportExcelButton({super.key, required this.onExport, this.tooltip = 'Export to Excel'});

  final Future<File> Function()? onExport;
  final String tooltip;

  @override
  State<ExportExcelButton> createState() => _ExportExcelButtonState();
}

class _ExportExcelButtonState extends State<ExportExcelButton> {
  bool _busy = false;

  Future<void> _run() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final file = await widget.onExport!();
      messenger.showSnackBar(SnackBar(
        content: Text('Exported to ${file.path}', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Export failed: $e', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.danger,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onExport != null && !_busy;
    return IconButton(
      tooltip: widget.tooltip,
      onPressed: enabled ? _run : null,
      icon: _busy
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : AppIcon(
              AppIcons.download,
              size: 18,
              color: enabled ? AppColors.textSecondaryFor(context) : AppColors.textMutedFor(context),
            ),
    );
  }
}
