import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/models/supplier_dto.dart';
import '../../data/purchase_providers.dart';
import '../purchase_form_controller.dart';

/// "Bill Details" panel: distributor, dates, challan/note numbers, pay
/// mode, transport particulars. Distributor is a live dropdown fed by
/// GET /api/suppliers; the rest write into [purchaseFormControllerProvider]
/// so the Save button can read a consistent snapshot at save time.
class BillDetailsCard extends ConsumerStatefulWidget {
  const BillDetailsCard({super.key});

  @override
  ConsumerState<BillDetailsCard> createState() => _BillDetailsCardState();
}

class _BillDetailsCardState extends ConsumerState<BillDetailsCard> {
  final _challanController = TextEditingController();
  final _noteController = TextEditingController();
  final _payModeController = TextEditingController(text: 'Credit');
  final _tpNoController = TextEditingController();
  final _stNoController = TextEditingController();

  @override
  void dispose() {
    for (final c in [_challanController, _noteController, _payModeController, _tpNoController, _stNoController]) {
      c.dispose();
    }
    super.dispose();
  }

  String _today() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.read(purchaseFormControllerProvider.notifier);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Bill Details', subtitle: 'Inward / GRN entry'),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 2, child: AppTextField(label: 'BILL NO.', hint: 'Auto on save')),
              const SizedBox(width: AppSpacing.md),
              Expanded(flex: 5, child: _SupplierField(form: form)),
              const SizedBox(width: AppSpacing.md),
              Expanded(flex: 2, child: AppTextField(label: 'DATE', controller: TextEditingController(text: _today()), enabled: false)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(label: 'CHALLAN NO.', hint: 'CHL-88142', controller: _challanController, onChanged: form.setChallanNo),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(label: 'NOTE NO.', hint: '—', controller: _noteController, onChanged: form.setNoteNo),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(label: 'PAY MODE', hint: 'Credit', controller: _payModeController, onChanged: form.setPayMode),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(label: 'TP NO.', hint: 'TP-2026-0091', controller: _tpNoController, onChanged: form.setTpNo),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: AppTextField(label: 'TP DATE', controller: TextEditingController(text: _today()), enabled: false)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(label: 'ST NO.', hint: 'ST-MH07', controller: _stNoController, onChanged: form.setStNo),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupplierField extends ConsumerWidget {
  const _SupplierField({required this.form});

  final PurchaseFormController form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final selectedId = ref.watch(purchaseFormControllerProvider).supplierId;

    return suppliersAsync.when(
      loading: () => const AppTextField(label: 'DISTRIBUTORS *', hint: 'Loading…', enabled: false),
      error: (_, __) => const AppTextField(label: 'DISTRIBUTORS *', hint: 'Could not load suppliers', enabled: false),
      data: (suppliers) {
        final matches = suppliers.where((s) => s.id == selectedId);
        final selected = matches.isEmpty ? null : matches.first;
        return AppDropdown<SupplierDto>(
          label: 'DISTRIBUTORS *',
          items: suppliers,
          itemLabel: (s) => s.name,
          value: selected,
          hint: 'Select a distributor',
          onChanged: (supplier) => form.setSupplier(supplier?.id),
        );
      },
    );
  }
}
