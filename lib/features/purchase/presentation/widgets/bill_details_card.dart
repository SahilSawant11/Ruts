import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
// import '../../../../shared/widgets/badges/status_chip.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../masters/data/models/supplier_dto.dart';
import '../../data/purchase_providers.dart';
import '../purchase_form_controller.dart';

/// Inward metadata strip at the top of the purchase workbench.
/// Embraces the app's pebble aesthetic: soft pill tags, rounded chips,
/// purple accents, and a high-density compact row matching InvoiceDetailsCard.
class BillDetailsCard extends ConsumerStatefulWidget {
  const BillDetailsCard({super.key, this.compact = true});

  final bool compact;

  @override
  ConsumerState<BillDetailsCard> createState() => _BillDetailsCardState();
}

class _BillDetailsCardState extends ConsumerState<BillDetailsCard> {
  final _challanController = TextEditingController();

  @override
  void dispose() {
    _challanController.dispose();
    super.dispose();
  }

  String _today() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year}';
  }

  void _openShippingDetailsDialog(BuildContext context, PurchaseFormController form, PurchaseFormState formState) {
    final noteController = TextEditingController(text: formState.noteNo ?? '');
    final tpController = TextEditingController(text: formState.tpNo ?? '');
    final stController = TextEditingController(text: formState.stNo ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundFor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Transport & Shipping Details',
              style: AppTypography.sectionTitle.copyWith(fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Remark',
                hint: '',
                controller: noteController,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'TP NO.',
                hint: 'e.g. TP-2026-0091',
                controller: tpController,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Vehicle NO.',
                hint: 'e.g. MH12-PS-0211',
                controller: stController,
              ),
            ],
          ),
        ),
        actions: [
          SecondaryButton(
            label: 'Done',
            onPressed: () {
              form.setNoteNo(noteController.text.trim());
              form.setTpNo(tpController.text.trim());
              form.setStNo(stController.text.trim());
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.read(purchaseFormControllerProvider.notifier);
    final formState = ref.watch(purchaseFormControllerProvider);
    // final pendingSyncAsync = ref.watch(pendingPurchaseSyncCountProvider);

    final isDark = AppColors.isDark(context);
    final stripBg = isDark ? AppColors.surfaceFor(context) : AppColors.surfaceAltFor(context);
    final borderColor = AppColors.borderFor(context);

    final hasShippingInfo = (formState.tpNo != null && formState.tpNo!.isNotEmpty) ||
        (formState.stNo != null && formState.stNo!.isNotEmpty) ||
        (formState.noteNo != null && formState.noteNo!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 7),
      decoration: BoxDecoration(
        color: stripBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Bill No
          _MetaField(
            label: 'BILL NO',
            child: Text(
              formState.billNo ?? 'AUTO',
              style: AppTypography.mono.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryFor(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _divider(borderColor),

          // Distributor (interactive pebble dropdown)
          Expanded(
            flex: 3,
            child: _SupplierField(ref: ref),
          ),
          _divider(borderColor),

          // Challan No (Inline editable field)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'INVOICE NO',
                  style: AppTypography.label.copyWith(
                    fontSize: 9.5,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 24,
                  child: TextField(
                    controller: _challanController,
                    onChanged: form.setChallanNo,
                    style: AppTypography.mono.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryFor(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'CHL-88142',
                      hintStyle: AppTypography.bodyMuted.copyWith(fontSize: 11),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _divider(borderColor),

          // Date
          _MetaField(
            label: 'DATE',
            value: _today(),
          ),
          _divider(borderColor),

          // Pay Mode Pill
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PAY MODE',
                  style: AppTypography.label.copyWith(
                    fontSize: 9.5,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
                const SizedBox(height: 2),
                PopupMenuButton<String>(
                  tooltip: 'Change Payment Mode',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: BorderSide(color: AppColors.borderFor(context)),
                  ),
                  color: AppColors.backgroundFor(context),
                  onSelected: form.setPayMode,
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'Credit', child: Text('Credit')),
                    const PopupMenuItem(value: 'Cash', child: Text('Cash')),
                    const PopupMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoftFor(context),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formState.payMode.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                            fontFamily: AppTypography.mono.fontFamily,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _divider(borderColor),

          // Shipping & Transport button
          InkWell(
            onTap: () => _openShippingDetailsDialog(context, form, formState),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SHIPPING / TP',
                    style: AppTypography.label.copyWith(
                      fontSize: 9.5,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasShippingInfo ? Icons.local_shipping_rounded : Icons.local_shipping_outlined,
                        size: 14,
                        color: hasShippingInfo ? AppColors.primary : AppColors.textSecondaryFor(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasShippingInfo
                            ? (formState.tpNo != null && formState.tpNo!.isNotEmpty
                                ? formState.tpNo!
                                : 'Configured')
                            : 'Add TP/ST',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasShippingInfo ? FontWeight.w700 : FontWeight.w500,
                          color: hasShippingInfo ? AppColors.primary : AppColors.textSecondaryFor(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _divider(borderColor),

          // Trailing: Offline status badge if queued (commented out for offline MVP)
          // pendingSyncAsync.maybeWhen(
          //   data: (count) => count > 0
          //       ? const StatusChip(label: 'Queued offline', tone: StatusChipTone.neutral)
          //       : const SizedBox.shrink(),
          //   orElse: () => const SizedBox.shrink(),
          // ),
        ],
      ),
    );
  }

  Widget _divider(Color color) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: color,
    );
  }
}

class _MetaField extends StatelessWidget {
  const _MetaField({
    required this.label,
    this.value,
    this.child,
  });

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(
            fontSize: 9.5,
            letterSpacing: 0.5,
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: 2),
        if (child != null)
          child!
        else
          Text(
            value ?? '—',
            style: AppTypography.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryFor(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class _SupplierField extends StatelessWidget {
  const _SupplierField({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final selectedId = ref.watch(purchaseFormControllerProvider).supplierId;

    return suppliersAsync.when(
      loading: () => const _MetaField(label: 'DISTRIBUTOR', value: 'Loading…'),
      error: (_, __) => const _MetaField(label: 'DISTRIBUTOR', value: 'Could not load'),
      data: (suppliers) {
        final matches = suppliers.where((s) => s.id == selectedId);
        final selected = matches.isEmpty ? null : matches.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DISTRIBUTOR',
              style: AppTypography.label.copyWith(
                fontSize: 9.5,
                letterSpacing: 0.5,
                color: AppColors.textSecondaryFor(context),
              ),
            ),
            const SizedBox(height: 2),
            PopupMenuButton<SupplierDto?>(
              tooltip: 'Select Distributor',
              initialValue: selected,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: AppColors.borderFor(context)),
              ),
              color: AppColors.backgroundFor(context),
              onSelected: (supplier) {
                ref.read(purchaseFormControllerProvider.notifier).setSupplier(supplier?.id);
              },
              itemBuilder: (context) => [
                for (final s in suppliers)
                  PopupMenuItem<SupplierDto?>(
                    value: s,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: s.id == selectedId ? FontWeight.w700 : FontWeight.w500,
                              color: s.id == selectedId ? AppColors.primary : AppColors.textPrimaryFor(context),
                            ),
                          ),
                        ),
                        if (s.contactNo != null && s.contactNo!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            s.contactNo!,
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondaryFor(context)),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      selected?.name ?? 'Select Distributor',
                      style: AppTypography.body.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected != null ? AppColors.primary : AppColors.textSecondaryFor(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 14,
                    color: AppColors.textSecondaryFor(context),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
