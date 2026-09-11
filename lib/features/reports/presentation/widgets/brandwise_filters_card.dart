import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/brandwise_report_provider.dart';

/// Single date picker + Generate button for the brandwise report.
class BrandwiseFiltersCard extends ConsumerStatefulWidget {
  const BrandwiseFiltersCard({super.key});

  @override
  ConsumerState<BrandwiseFiltersCard> createState() => _BrandwiseFiltersCardState();
}

class _BrandwiseFiltersCardState extends ConsumerState<BrandwiseFiltersCard> {
  DateTime? _pendingDate;
  DateTime? _lastSynced;

  String _fmt(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')}-${months[d.month - 1]}-${d.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pendingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _pendingDate = picked);
  }

  void _generate() {
    if (_pendingDate == null) return;
    ref.read(brandwiseReportDateProvider.notifier).state = _pendingDate!;
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(brandwiseReportDateProvider);

    if (_lastSynced != current) {
      _lastSynced = current;
      _pendingDate = current;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Filters'),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _dateField('REPORT DATE', _pendingDate ?? current)),
              const SizedBox(width: AppSpacing.md),
              // Spacers so the Generate button isn't stretched across the full width
              const Expanded(flex: 2, child: SizedBox.shrink()),
              PrimaryButton(label: 'Generate', icon: Icons.search_rounded, onPressed: _generate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderFor(context)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.textMutedFor(context)),
                const SizedBox(width: 8),
                Text(
                  _fmt(value),
                  style: AppTypography.body.copyWith(color: AppColors.textPrimaryFor(context)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
