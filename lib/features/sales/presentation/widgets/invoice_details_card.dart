import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/models/customer_dto.dart';
import '../../data/sales_providers.dart';
import '../sales_providers.dart';

/// "Invoice Details" panel: bill number, customer, type, date, pay
/// mode, license fields and running balance.
///
/// Bill No / Date are auto-generated (read-only), Customer is a live
/// dropdown fed by GET /api/customers. License fields stay static for
/// now — they'll wire up once a StoreLicense endpoint exists.
class InvoiceDetailsCard extends ConsumerWidget {
  const InvoiceDetailsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billNo = ref.watch(billNoProvider);
    final today = _formatToday();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Invoice Details',
            subtitle: 'Auto-numbered counter sale',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'BILL NO.',
                  controller: TextEditingController(text: billNo),
                  enabled: false,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(flex: 2, child: _CustomerField(ref: ref)),
              const SizedBox(width: AppSpacing.md),
              const Expanded(child: AppTextField(label: 'TYPE', hint: 'CounterSale.Sale', enabled: false)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(label: 'DATE', controller: TextEditingController(text: today), enabled: false),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(child: AppTextField(label: 'PAY MODE', hint: 'Set in Payment panel →', enabled: false)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: AppTextField(label: 'LICENSE NO.', hint: 'Life Time')),
              SizedBox(width: AppSpacing.md),
              Expanded(child: AppTextField(label: 'LICENSE NAME', hint: 'J.R.TOLARAM')),
              SizedBox(width: AppSpacing.md),
              Expanded(child: AppTextField(label: 'VALIDITY', hint: '—')),
              SizedBox(width: AppSpacing.md),
              Expanded(child: AppTextField(label: 'BALANCE', hint: '0.00')),
            ],
          ),
        ],
      ),
    );
  }

  String _formatToday() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year}';
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
      loading: () => const AppTextField(label: 'CUSTOMER', hint: 'Loading…', enabled: false),
      error: (_, __) => const AppTextField(label: 'CUSTOMER', hint: 'Could not load customers', enabled: false),
      data: (customers) {
        final matches = customers.where((c) => c.id == selectedId);
        final selected = matches.isEmpty ? null : matches.first;
        return AppDropdown<CustomerDto>(
          label: 'CUSTOMER',
          items: customers,
          itemLabel: (c) => c.name,
          value: selected,
          hint: 'Counter Sale',
          onChanged: (customer) {
            ref.read(selectedCustomerIdProvider.notifier).state = customer?.id;
          },
        );
      },
    );
  }
}
