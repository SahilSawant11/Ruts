import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../data/masters_providers.dart';

final shopPrefixProvider = FutureProvider<String>((ref) => ref.watch(appDatabaseProvider).shopPrefix());

/// "Prefix CB ✎" — the store's shop prefix for counter brand IDs. One value
/// for the whole store; changing it re-prefixes every ID, numbers stay.
class ShopPrefixChip extends ConsumerWidget {
  const ShopPrefixChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefix = ref.watch(shopPrefixProvider).valueOrNull ?? '…';
    return Tooltip(
      message: 'Shop prefix for counter brand IDs ($prefix-0001)',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () => _edit(context, ref, prefix),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.borderFor(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PREFIX ', style: AppTypography.label.copyWith(color: AppColors.textMutedFor(context))),
              Text(prefix, style: AppTypography.mono.copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              AppIcon(AppIcons.edit, size: 12, color: AppColors.textMutedFor(context)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current == '…' ? '' : current);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Shop prefix'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(label: 'PREFIX', controller: controller, autofocus: true, hint: 'e.g. RS'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Counter brand IDs are PREFIX-0001, PREFIX-0002… Changing it updates every ID; the numbers stay the same.',
                style: AppTypography.caption.copyWith(color: AppColors.textMutedFor(ctx)),
              ),
            ],
          ),
        ),
        actions: [
          SecondaryButton(label: 'Cancel', onPressed: () => Navigator.of(ctx).pop()),
          PrimaryButton(label: 'Save', onPressed: () => Navigator.of(ctx).pop(controller.text)),
        ],
      ),
    );
    controller.dispose();
    if (next == null) return;
    try {
      await ref.read(appDatabaseProvider).setShopPrefix(next);
      ref.invalidate(shopPrefixProvider);
      ref.invalidate(materialsListProvider);
      await ref.read(mastersRepositoryProvider).onMaterialsChanged?.call();
    } on ArgumentError catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${e.message}')));
    }
  }
}
