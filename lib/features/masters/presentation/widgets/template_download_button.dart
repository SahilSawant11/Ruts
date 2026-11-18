import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../data/master_import_service.dart';
import '../../data/masters_providers.dart';

/// Saves a blank import template for [target] to Downloads/Caskly Templates.
class TemplateDownloadButton extends ConsumerStatefulWidget {
  const TemplateDownloadButton({super.key, required this.target});

  final MasterImportTarget target;

  @override
  ConsumerState<TemplateDownloadButton> createState() => _TemplateDownloadButtonState();
}

class _TemplateDownloadButtonState extends ConsumerState<TemplateDownloadButton> {
  bool _busy = false;

  Future<void> _download() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      var categories = const <String>[];
      var packings = const <String>[];
      if (widget.target == MasterImportTarget.materials) {
        categories = [for (final c in await ref.read(categoriesListProvider.future)) c.name];
        packings = [for (final p in await ref.read(packingsListProvider.future)) p.name];
      }
      final file = await ref
          .read(masterTemplateServiceProvider)
          .save(widget.target, categories: categories, packings: packings);
      messenger.showSnackBar(SnackBar(
        content: Text('Template saved: ${file.path}', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Could not save template: $e', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.danger,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Download a blank Excel template to fill and import',
      child: SecondaryButton(
        label: _busy ? 'Saving…' : 'Template',
        icon: AppIcons.download,
        dense: true,
        onPressed: _busy ? null : _download,
      ),
    );
  }
}
