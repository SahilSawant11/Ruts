import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../../../shared/widgets/badges/tag_pill.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../../inventory/data/inventory_providers.dart';
import '../../data/models/sales_return_models.dart';
import '../../data/sales_providers.dart';

class SalesReturnScreen extends ConsumerStatefulWidget {
  const SalesReturnScreen({super.key});

  @override
  ConsumerState<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends ConsumerState<SalesReturnScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  bool _isProcessing = false;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-${_months[d.month - 1]}-${d.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: AppColors.isDark(context) ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val.trim();
    });
  }

  Future<void> _processReturn(SalesBillDetailDto bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundFor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger, size: 24),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Confirm Sales Return'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to return Bill ${bill.billNo}?',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Total Refund Amount: ₹${bill.totalAmount.toStringAsFixed(2)}',
              style: AppTypography.body.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceFor(ctx),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderFor(ctx)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('Soft-deletes the sales bill record', style: AppTypography.caption),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Restores ${bill.lineItems.fold<int>(0, (sum, i) => sum + i.quantity)} item(s) back to inventory',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondaryFor(ctx))),
          ),
          DangerButton(
            label: 'Confirm Return',
            icon: Icons.assignment_return_outlined,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(salesRepositoryProvider).returnSalesBill(bill.id);

      ref.invalidate(salesBillsListProvider);
      ref.invalidate(todaysBillsProvider);
      ref.invalidate(inventoryListProvider);
      ref.invalidate(inventoryOverviewProvider);
      ref.invalidate(filteredInventoryOverviewProvider);

      ref.read(selectedSalesBillProvider.notifier).state = null;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bill ${bill.billNo} returned successfully. Inventory stock restored.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process return: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(
      salesBillsListProvider(SalesReturnFilter(search: _searchQuery, date: _selectedDate)),
    );
    final selectedBill = ref.watch(selectedSalesBillProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 380,
                  child: _buildBillsList(billsAsync, selectedBill),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildDetailPanel(selectedBill),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sales Return',
                style: AppTypography.h1.copyWith(
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Look up customer sales bills by number or date to process soft-delete returns and restore stock.',
                style: AppTypography.bodyMuted.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ),
        // Date Picker Button
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
            decoration: BoxDecoration(
              color: _selectedDate != null
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: _selectedDate != null ? AppColors.primary : AppColors.borderFor(context),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: _selectedDate != null ? AppColors.primary : AppColors.textSecondaryFor(context),
                ),
                const SizedBox(width: 6),
                Text(
                  _selectedDate == null ? 'All Dates' : _formatDate(_selectedDate!),
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _selectedDate != null ? AppColors.primary : AppColors.textPrimaryFor(context),
                  ),
                ),
                if (_selectedDate != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _selectedDate = null),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 280,
          child: AppTextField(
            label: '',
            hint: 'Search Bill # or Customer…',
            controller: _searchController,
            onChanged: _onSearchChanged,
            suffix: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : const Icon(Icons.search_rounded, size: 18),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SecondaryButton(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(salesBillsListProvider),
        ),
      ],
    );
  }

  Widget _buildBillsList(
    AsyncValue<List<SalesBillDetailDto>> billsAsync,
    SalesBillDetailDto? selectedBill,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Sales Bills',
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
                ),
                billsAsync.maybeWhen(
                  data: (bills) => StatusChip(
                    label: '${bills.length} bills',
                    tone: StatusChipTone.neutral,
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.sm),
          Expanded(
            child: billsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Error loading bills: $err',
                    style: AppTypography.caption.copyWith(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (bills) {
                if (bills.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 42, color: AppColors.textMutedFor(context)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _searchQuery.isEmpty ? 'No sales bills found' : 'No bills match "$_searchQuery"',
                          style: AppTypography.bodyMuted,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: bills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    final isSelected = selectedBill?.id == bill.id;

                    return Material(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surfaceFor(context),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: InkWell(
                        onTap: () {
                          ref.read(selectedSalesBillProvider.notifier).state = bill;
                        },
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.borderFor(context),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    bill.billNo,
                                    style: AppTypography.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? AppColors.primary : AppColors.textPrimaryFor(context),
                                    ),
                                  ),
                                  Text(
                                    '₹${bill.totalAmount.toStringAsFixed(2)}',
                                    style: AppTypography.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimaryFor(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      bill.customerName ?? 'Walk-in Customer',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondaryFor(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  TagPill(label: bill.payMode),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    bill.billDate.split('T').first,
                                    style: AppTypography.mono.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textMutedFor(context),
                                    ),
                                  ),
                                  Text(
                                    '${bill.lineItems.length} item(s)',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textMutedFor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(SalesBillDetailDto? bill) {
    if (bill == null) {
      return AppCard(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_return_outlined,
                size: 64,
                color: AppColors.textMutedFor(context),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Select a Sales Bill to Return',
                style: AppTypography.h2.copyWith(color: AppColors.textSecondaryFor(context)),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Choose an invoice from the left panel to inspect items and initiate a return.',
                style: AppTypography.bodyMuted,
              ),
            ],
          ),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              border: Border(bottom: BorderSide(color: AppColors.borderFor(context))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(bill.billNo, style: AppTypography.h2),
                        const SizedBox(width: AppSpacing.sm),
                        StatusChip(label: bill.status.toUpperCase(), tone: StatusChipTone.neutral),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customer: ${bill.customerName ?? 'Walk-in Customer'} · Date: ${bill.billDate.split('T').first} · Mode: ${bill.payMode}',
                      style: AppTypography.bodyMuted,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total Bill Amount', style: AppTypography.caption),
                    Text(
                      '₹${bill.totalAmount.toStringAsFixed(2)}',
                      style: AppTypography.h1.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Itemized Table
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Line Items (${bill.lineItems.length})',
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderFor(context)),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FixedColumnWidth(40),
                        1: FixedColumnWidth(120),
                        2: FlexColumnWidth(3),
                        3: FlexColumnWidth(1),
                        4: FixedColumnWidth(70),
                        5: FixedColumnWidth(80),
                        6: FixedColumnWidth(80),
                        7: FixedColumnWidth(100),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceFor(context),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
                          ),
                          children: [
                            _th('#'),
                            _th('Barcode'),
                            _th('Material Name'),
                            _th('Batch / Pack'),
                            _th('Qty'),
                            _th('Rate'),
                            _th('Tax %'),
                            _th('Amount', align: TextAlign.right),
                          ],
                        ),
                        ...bill.lineItems.map(
                          (item) => TableRow(
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: AppColors.borderFor(context))),
                            ),
                            children: [
                              _td(item.lineNumber.toString()),
                              _td(item.barcodeNo, mono: true),
                              _td(item.materialName),
                              _td('${item.batchNo ?? '-'} / ${item.packing ?? '-'}'),
                              _td(item.quantity.toString(), bold: true),
                              _td('₹${item.rate.toStringAsFixed(2)}'),
                              _td('${item.taxPercent}%'),
                              _td('₹${item.amount.toStringAsFixed(2)}', align: TextAlign.right, bold: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg)),
              border: Border(top: BorderSide(color: AppColors.borderFor(context))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SecondaryButton(
                  label: 'Clear Selection',
                  icon: Icons.close_rounded,
                  onPressed: () {
                    ref.read(selectedSalesBillProvider.notifier).state = null;
                  },
                ),
                DangerButton(
                  label: _isProcessing ? 'Processing…' : 'Process Sales Return',
                  icon: Icons.assignment_return_rounded,
                  onPressed: _isProcessing ? null : () => _processReturn(bill),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _th(String label, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
        textAlign: align,
      ),
    );
  }

  Widget _td(String val, {bool mono = false, bool bold = false, TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
      child: Text(
        val,
        style: mono
            ? AppTypography.mono.copyWith(fontSize: 12)
            : AppTypography.body.copyWith(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
        textAlign: align,
      ),
    );
  }
}
