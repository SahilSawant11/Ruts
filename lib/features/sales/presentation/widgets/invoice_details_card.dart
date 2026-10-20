import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/customer_dto.dart';
import '../../data/sales_providers.dart';
import '../../../masters/data/masters_providers.dart';
import '../../../masters/data/models/license_holder_dto.dart';
import '../cart_controller.dart';
import '../sales_providers.dart';

/// Compact 1-row metadata strip at the top of the sales workbench.
/// Embraces the app's pebble aesthetic: soft pill tags, rounded chips,
/// purple accents, and high-density 42px height.
class InvoiceDetailsCard extends ConsumerWidget {
  const InvoiceDetailsCard({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billNo = ref.watch(billNoProvider);
    final payMode = ref.watch(paymentMethodProvider);
    final totalAmount = ref.watch(cartControllerProvider.select((s) => s.totalAmount));

    final payModeText = switch (payMode) {
      PaymentMethod.cash => 'CASH',
      PaymentMethod.card => 'CARD',
      PaymentMethod.upi => 'UPI',
    };

    final isDark = AppColors.isDark(context);
    final stripBg = isDark ? AppColors.surfaceFor(context) : AppColors.surfaceAltFor(context);
    final borderColor = AppColors.borderFor(context);

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
              billNo,
              style: AppTypography.mono.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryFor(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _divider(borderColor),

          // Customer (interactive pebble dropdown)
          Expanded(
            flex: 3,
            child: _CustomerField(ref: ref),
          ),
          _divider(borderColor),

          // License
          Expanded(
            flex: 3,
            child: _LicenseHolderField(ref: ref),
          ),
          _divider(borderColor),

          // Type
          Expanded(
            flex: 2,
            child: _MetaField(
              label: 'TYPE',
              value: ref.watch(activeLicenseHolderProvider)?.whereGranted ?? 'Life Time',
            ),
          ),
          _divider(borderColor),

          // Pay Mode
          Expanded(
            flex: 2,
            child: _MetaField(
              label: 'PAY MODE',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySoftFor(context),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  payModeText,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    fontFamily: AppTypography.mono.fontFamily,
                  ),
                ),
              ),
            ),
          ),
          _divider(borderColor),

          // Balance Due
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BALANCE DUE',
                  style: AppTypography.label.copyWith(
                    fontSize: 9.5,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: AppTypography.mono.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: totalAmount > 0 ? AppColors.danger : AppColors.success,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(Color color) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 10),
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

class _CustomerField extends StatelessWidget {
  const _CustomerField({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final selectedId = ref.watch(selectedCustomerIdProvider);

    return customersAsync.when(
      loading: () => const _MetaField(label: 'CUSTOMER', value: 'Loading…'),
      error: (_, __) => const _MetaField(label: 'CUSTOMER', value: 'Counter Sale (Walk-in)'),
      data: (customers) {
        final matches = customers.where((c) => c.id == selectedId);
        final selected = matches.isEmpty ? null : matches.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CUSTOMER',
              style: AppTypography.label.copyWith(
                fontSize: 9.5,
                letterSpacing: 0.5,
                color: AppColors.textSecondaryFor(context),
              ),
            ),
            const SizedBox(height: 2),
            PopupMenuButton<CustomerDto?>(
              tooltip: 'Select Customer',
              initialValue: selected,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: AppColors.borderFor(context)),
              ),
              color: AppColors.backgroundFor(context),
              onSelected: (customer) {
                ref.read(selectedCustomerIdProvider.notifier).state = customer?.id;
              },
              itemBuilder: (context) => [
                PopupMenuItem<CustomerDto?>(
                  value: null,
                  child: Text(
                    'Counter Sale (Walk-in)',
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                ...customers.map(
                  (c) => PopupMenuItem<CustomerDto?>(
                    value: c,
                    child: Text(c.name, style: AppTypography.body.copyWith(fontSize: 12)),
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.backgroundFor(context),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        selected?.name ?? 'Counter Sale (Walk-in)',
                        style: AppTypography.body.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryFor(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LicenseHolderField extends StatelessWidget {
  const _LicenseHolderField({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final activeHolder = ref.watch(activeLicenseHolderProvider);
    final holdersAsync = ref.watch(licenseHoldersListProvider);

    final displayValue = activeHolder != null
        ? '${activeHolder.permitNo} · ${activeHolder.name}'
        : 'No Permit Selected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'LICENSE',
          style: AppTypography.label.copyWith(
            fontSize: 9.5,
            letterSpacing: 0.5,
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: 2),
        holdersAsync.maybeWhen(
          data: (holders) {
            if (holders.isEmpty) {
              return Text(
                'No Permits Added',
                style: AppTypography.bodyMutedFor(context).copyWith(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              );
            }

            return PopupMenuButton<LicenseHolderDto>(
              tooltip: 'Change License Holder (Auto-rotates each bill)',
              initialValue: activeHolder,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: AppColors.borderFor(context)),
              ),
              color: AppColors.backgroundFor(context),
              onSelected: (holder) {
                ref.read(selectedLicenseHolderProvider.notifier).state = holder;
              },
              itemBuilder: (context) => [
                ...holders.map(
                  (h) => PopupMenuItem<LicenseHolderDto>(
                    value: h,
                    child: Row(
                      children: [
                        Text(
                          h.permitNo,
                          style: AppTypography.mono.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            h.name,
                            style: AppTypography.body.copyWith(
                              fontSize: 12,
                              fontWeight: h.id == activeHolder?.id
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (h.id == activeHolder?.id)
                          const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.backgroundFor(context),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayValue,
                        style: AppTypography.body.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryFor(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            );
          },
          orElse: () => Text(
            displayValue,
            style: AppTypography.body.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryFor(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
