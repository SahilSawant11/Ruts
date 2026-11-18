import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/sales_providers.dart';
import '../../../masters/data/masters_providers.dart';
import '../../../masters/data/models/license_holder_dto.dart';
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
    final isNewPermit = ref.watch(newPermitModeProvider);
    final isNewBuyer = isNewPermit && ref.watch(newFrequentBuyerProvider);

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

          if (isNewPermit) ...[
            // New → Walk in: name + license number. New → Frequent Buyer:
            // name only (the bill keeps the rotating permit).
            Expanded(
              flex: 3,
              child: _NewPermitBox(
                label: isNewBuyer ? 'FREQUENT BUYER NAME' : 'WALK-IN NAME',
                hint: 'Customer name',
                isName: true,
              ),
            ),
            _divider(borderColor),
            if (isNewBuyer)
              Expanded(flex: 3, child: _LicenseHolderField(ref: ref))
            else
              const Expanded(
                flex: 3,
                child: _NewPermitBox(label: 'LICENSE NO', hint: 'Permit / license no.', isName: false),
              ),
            IconButton(
              tooltip: 'Cancel new customer',
              visualDensity: VisualDensity.compact,
              icon: AppIcon(AppIcons.close, size: 16, color: AppColors.textSecondaryFor(context)),
              onPressed: () {
                ref.read(newPermitModeProvider.notifier).state = false;
                ref.read(newFrequentBuyerProvider.notifier).state = false;
                ref.read(newPermitNameProvider.notifier).state = '';
                ref.read(newPermitNoProvider.notifier).state = '';
              },
            ),
            _divider(borderColor),
          ] else ...[
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
          ],

          // Type
          Expanded(
            flex: 2,
            child: _MetaField(
              label: 'PERMIT TYPE',
              value: isNewPermit && !isNewBuyer
                  ? LicenseHolderDto.oneTime
                  : ref.watch(activeLicenseHolderProvider)?.validity ?? LicenseHolderDto.lifetime,
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

const _walkIn = '__walk_in__';
const _newCustomer = '__new__';
const _newFrequentBuyer = '__new_frequent_buyer__';
const _licenseHolderLabel = 'License Holder';

/// One of the two inline boxes shown for Customer → NEW.
class _NewPermitBox extends ConsumerStatefulWidget {
  const _NewPermitBox({required this.label, required this.hint, required this.isName});

  final String label;
  final String hint;
  final bool isName;

  @override
  ConsumerState<_NewPermitBox> createState() => _NewPermitBoxState();
}

class _NewPermitBoxState extends ConsumerState<_NewPermitBox> {
  late final TextEditingController _controller;

  StateProvider<String> get _provider => widget.isName ? newPermitNameProvider : newPermitNoProvider;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(_provider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MetaField(
      label: widget.label,
      child: SizedBox(
        height: 24,
        child: TextField(
          controller: _controller,
          autofocus: widget.isName,
          textInputAction: TextInputAction.next,
          textCapitalization: widget.isName ? TextCapitalization.words : TextCapitalization.characters,
          onChanged: (v) => ref.read(_provider.notifier).state = v,
          style: AppTypography.body.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryFor(context),
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hint,
            hintStyle: AppTypography.bodyMutedFor(context).copyWith(fontSize: 11),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            filled: true,
            fillColor: AppColors.backgroundFor(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              borderSide: BorderSide(color: AppColors.borderFor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              borderSide: BorderSide(color: AppColors.borderFor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerField extends StatelessWidget {
  const _CustomerField({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final buyers = ref.watch(frequentBuyersProvider).valueOrNull ?? const <LicenseHolderDto>[];
    final remoteCustomers = ref.watch(customersProvider).valueOrNull ?? const [];
    final selectedId = ref.watch(selectedCustomerIdProvider);
    final options = <(String, String)>[
      for (final b in buyers) (b.id, b.name),
      for (final c in remoteCustomers) (c.id, c.name),
    ];
    final selectedName = options.where((o) => o.$1 == selectedId).map((o) => o.$2).firstOrNull;

    Widget newItem(String label) => Row(
          children: [
            const AppIcon(AppIcons.add, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'New → $label',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppColors.primaryInk,
              ),
            ),
          ],
        );

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
        PopupMenuButton<String>(
          tooltip: 'Select Customer',
          initialValue: selectedName != null ? selectedId : _walkIn,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: AppColors.borderFor(context)),
          ),
          color: AppColors.backgroundFor(context),
          onSelected: (value) {
            if (value == _newCustomer || value == _newFrequentBuyer) {
              ref.read(selectedCustomerIdProvider.notifier).state = null;
              ref.read(newFrequentBuyerProvider.notifier).state = value == _newFrequentBuyer;
              ref.read(newPermitModeProvider.notifier).state = true;
              return;
            }
            ref.read(selectedCustomerIdProvider.notifier).state = value == _walkIn ? null : value;
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(value: _newCustomer, child: newItem('Walk in')),
            PopupMenuItem<String>(value: _newFrequentBuyer, child: newItem('Frequent Buyer')),
            PopupMenuItem<String>(
              value: _walkIn,
              child: Text(
                _licenseHolderLabel,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
            if (options.isNotEmpty) const PopupMenuDivider(),
            ...options.map(
              (o) => PopupMenuItem<String>(
                value: o.$1,
                child: Text(o.$2, style: AppTypography.body.copyWith(fontSize: 12)),
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
                    selectedName ?? _licenseHolderLabel,
                    style: AppTypography.body.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryFor(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const AppIcon(
                  AppIcons.arrowDropDown,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LicenseHolderField extends StatelessWidget {
  const _LicenseHolderField({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final activeHolder = ref.watch(activeLicenseHolderProvider);
    final holdersAsync = ref.watch(rotationLicenseHoldersProvider);

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
                            color: AppColors.primaryInk,
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
                          const AppIcon(AppIcons.check, size: 16, color: AppColors.primary),
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
                    const AppIcon(
                      AppIcons.arrowDropDown,
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
