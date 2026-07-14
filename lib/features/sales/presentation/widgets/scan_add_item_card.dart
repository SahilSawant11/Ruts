import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../cart_controller.dart';

/// Primary data-entry panel: scan/type a barcode, hit Add (or press
/// Enter), and it's looked up via the API and appended to the cart.
class ScanAddItemCard extends ConsumerStatefulWidget {
  const ScanAddItemCard({super.key});

  static const _categories = ['Whisky', 'Beer', 'Wine', 'Rum', 'Vodka', 'Soft Drink'];

  @override
  ConsumerState<ScanAddItemCard> createState() => _ScanAddItemCardState();
}

class _ScanAddItemCardState extends ConsumerState<ScanAddItemCard> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Scanner auto-focus, matching the reference design's intent.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final barcode = _controller.text;
    if (barcode.trim().isEmpty) return;
    await ref.read(cartControllerProvider.notifier).addByBarcode(barcode);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Scan / Add Item',
            subtitle: 'Primary action — scanner auto-focuses on load',
            trailing: cart.isScanning
                ? const StatusChip(label: 'Looking up…', tone: StatusChipTone.neutral)
                : const StatusChip(label: 'Scanner Ready'),
          ),
          const SizedBox(height: AppSpacing.md),
          _scanRow(),
          if (cart.scanError != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(cart.scanError!, style: AppTypography.caption.copyWith(color: AppColors.danger)),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: ScanAddItemCard._categories.map(_categoryChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _scanRow() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_scanner_rounded, size: 17, color: Colors.white),
                SizedBox(width: 6),
                Text('BARCODE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (_) => _submit(),
              style: AppTypography.body,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Scan barcode or type item code, then press Enter.',
                hintStyle: AppTypography.bodyMuted,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          PrimaryButton(label: '+ Add', onPressed: _submit, icon: Icons.add_rounded),
        ],
      ),
    );
  }

  Widget _categoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.bodyMuted.copyWith(fontWeight: FontWeight.w700, fontSize: 11.5),
      ),
    );
  }
}
