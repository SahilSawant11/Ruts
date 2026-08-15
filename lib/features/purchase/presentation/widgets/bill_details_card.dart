import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../../masters/data/models/supplier_dto.dart';
import '../../data/purchase_providers.dart';
import '../purchase_form_controller.dart';

/// "Bill Details" panel: distributor, dates, challan/note numbers, pay
/// mode, transport particulars. Distributor is a live dropdown fed by
/// GET /api/suppliers; the rest write into [purchaseFormControllerProvider]
/// so the Save button can read a consistent snapshot at save time.
class BillDetailsCard extends ConsumerStatefulWidget {
  const BillDetailsCard({super.key, this.compact = false});

  final bool compact;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactWidth = constraints.maxWidth < 1100;
        final gap = widget.compact ? AppSpacing.sm : AppSpacing.md;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Bill Details', subtitle: 'Inward / GRN entry'),
              SizedBox(height: widget.compact ? AppSpacing.sm : AppSpacing.md),
              if (!compactWidth)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: AppTextField(label: 'BILL NO.', hint: 'Auto on save'),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      flex: 5,
                      child: _SupplierField(form: form),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        label: 'DATE',
                        controller: TextEditingController(text: _today()),
                        enabled: false,
                      ),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth,
                      child: _SupplierField(form: form),
                    ),
                    SizedBox(
                      width: (constraints.maxWidth - gap) / 2,
                      child: const AppTextField(label: 'BILL NO.', hint: 'Auto on save'),
                    ),
                    SizedBox(
                      width: (constraints.maxWidth - gap) / 2,
                      child: AppTextField(
                        label: 'DATE',
                        controller: TextEditingController(text: _today()),
                        enabled: false,
                      ),
                    ),
                  ],
                ),
              SizedBox(height: gap),
              if (!compactWidth)
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'CHALLAN NO.',
                        hint: 'CHL-88142',
                        controller: _challanController,
                        onChanged: form.setChallanNo,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: AppTextField(
                        label: 'NOTE NO.',
                        hint: '—',
                        controller: _noteController,
                        onChanged: form.setNoteNo,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: AppTextField(
                        label: 'PAY MODE',
                        hint: 'Credit',
                        controller: _payModeController,
                        onChanged: form.setPayMode,
                      ),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: (constraints.maxWidth - gap) / 2,
                      child: AppTextField(
                        label: 'CHALLAN NO.',
                        hint: 'CHL-88142',
                        controller: _challanController,
                        onChanged: form.setChallanNo,
                      ),
                    ),
                    SizedBox(
                      width: (constraints.maxWidth - gap) / 2,
                      child: AppTextField(
                        label: 'NOTE NO.',
                        hint: '—',
                        controller: _noteController,
                        onChanged: form.setNoteNo,
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth,
                      child: AppTextField(
                        label: 'PAY MODE',
                        hint: 'Credit',
                        controller: _payModeController,
                        onChanged: form.setPayMode,
                      ),
                    ),
                  ],
                ),
              SizedBox(height: gap),
              if (!compactWidth)
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'TP NO.',
                        hint: 'TP-2026-0091',
                        controller: _tpNoController,
                        onChanged: form.setTpNo,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: AppTextField(
                        label: 'TP DATE',
                        controller: TextEditingController(text: _today()),
                        enabled: false,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: AppTextField(
                        label: 'ST NO.',
                        hint: 'ST-MH07',
                        controller: _stNoController,
                        onChanged: form.setStNo,
                      ),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: (constraints.maxWidth - gap) / 2,
                      child: AppTextField(
                        label: 'TP NO.',
                        hint: 'TP-2026-0091',
                        controller: _tpNoController,
                        onChanged: form.setTpNo,
                      ),
                    ),
                    SizedBox(
                      width: (constraints.maxWidth - gap) / 2,
                      child: AppTextField(
                        label: 'TP DATE',
                        controller: TextEditingController(text: _today()),
                        enabled: false,
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth,
                      child: AppTextField(
                        label: 'ST NO.',
                        hint: 'ST-MH07',
                        controller: _stNoController,
                        onChanged: form.setStNo,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
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
