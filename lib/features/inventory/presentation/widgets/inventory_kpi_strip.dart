import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/inventory_providers.dart';

/// Three-card KPI strip for the Inventory screen.
///
///  Card 1 – Total SCM Codes   (static)
///  Card 2 – Net Inventory Worth (Σ saleRate × qty)
///  Card 3 – Low Stock count   (interactive — tap pins/unpins filter; 'i' btn configures threshold)
class InventoryKpiStrip extends ConsumerWidget {
  const InventoryKpiStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(inventoryOverviewProvider);
    final lowStockPinned = ref.watch(inventoryLowStockPinProvider);
    final lowStockThreshold = ref.watch(inventoryLowStockThresholdProvider);

    return overviewAsync.when(
      loading: () => const _SkeletonRow(),
      error: (_, __) => const _SkeletonRow(),
      data: (items) {
        final totalScmCodes = items.length;
        final lowStockCount =
            items.where((i) => i.isAtRiskFor(lowStockThreshold)).length;
        final netWorth = items.fold<double>(0, (s, i) => s + i.onHandValue);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card 1 — Total SCM Codes
              Expanded(
                child: _KpiCard(
                  icon: Icons.tag_rounded,
                  iconColor: AppColors.primary,
                  label: 'Total SCM Codes',
                  value: '$totalScmCodes',
                  sub: 'active codes in catalog',
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Card 2 — Net Inventory Worth
              Expanded(
                child: _KpiCard(
                  icon: Icons.currency_rupee_rounded,
                  iconColor: AppColors.success,
                  label: 'Net Inventory Worth',
                  value: _rupees(netWorth),
                  sub: 'at current sale rates',
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Card 3 — Low Stock (interactive + info/threshold button)
              Expanded(
                child: _LowStockCard(
                  count: lowStockCount,
                  isPinned: lowStockPinned,
                  threshold: lowStockThreshold,
                  onTap: () => ref
                      .read(inventoryLowStockPinProvider.notifier)
                      .state = !lowStockPinned,
                  onConfigureThreshold: () =>
                      _showThresholdDialog(context, ref, lowStockThreshold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  static String _rupees(double v) {
    if (v <= 0) return '₹ 0';
    if (v >= 10000000) return '₹ ${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '₹ ${(v / 100000).toStringAsFixed(2)} L';
    return '₹ ${_indianComma(v.toInt())}';
  }

  static String _indianComma(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      if (i != 0 && (rest.length - i) % 2 == 0) buf.write(',');
      buf.write(rest[i]);
    }
    return '${buf.toString()},$last3';
  }
}

// ── Shared KPI card shell ────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.sub,
    this.isPinned = false,
    this.onTap,
    this.trailingAction,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? sub;
  final bool isPinned;
  final VoidCallback? onTap;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final borderColor =
        isPinned ? AppColors.warning : AppColors.borderFor(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.backgroundFor(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: isPinned ? 1.5 : 1.0),
        boxShadow: AppColors.cardShadowFor(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          splashColor: iconColor.withValues(alpha: 0.08),
          highlightColor: iconColor.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark
                            ? iconColor.withValues(alpha: 0.15)
                            : iconColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 20, color: iconColor),
                    ),
                    const Spacer(),
                    if (trailingAction != null) trailingAction!,
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  value,
                  style: AppTypography.h1.copyWith(
                    fontSize: 28,
                    height: 1.1,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTypography.label.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedFor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Interactive Low Stock card with Info / Threshold Button ──────────────────

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({
    required this.count,
    required this.isPinned,
    required this.threshold,
    required this.onTap,
    required this.onConfigureThreshold,
  });

  final int count;
  final bool isPinned;
  final int threshold;
  final VoidCallback onTap;
  final VoidCallback onConfigureThreshold;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return _KpiCard(
      icon: Icons.warning_amber_rounded,
      iconColor: count > 0 ? AppColors.warning : AppColors.success,
      label: 'Low Stock Items',
      value: '$count',
      sub: isPinned
          ? 'Filter active (≤ $threshold units) · Tap to clear'
          : 'Items with ≤ $threshold units · Tap to filter',
      isPinned: isPinned,
      onTap: onTap,
      trailingAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPinned) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.warning.withValues(alpha: 0.18)
                    : AppColors.warningSoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'FILTERED',
                style: AppTypography.label.copyWith(
                  color: AppColors.warning,
                  fontSize: 9,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Tooltip(
            message: 'Set low stock threshold (current: ≤ $threshold units)',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onConfigureThreshold,
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.surfaceAltFor(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.borderFor(context),
                    ),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Threshold Configuration Dialog ───────────────────────────────────────────

void _showThresholdDialog(
    BuildContext context, WidgetRef ref, int currentThreshold) {
  final controller = TextEditingController(text: '$currentThreshold');

  showDialog<void>(
    context: context,
    builder: (ctx) {
      final isDark = AppColors.isDark(ctx);
      int selectedValue = currentThreshold;

      return StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          void updateValue(int val) {
            setDialogState(() {
              selectedValue = val;
              controller.text = '$val';
            });
          }

          return AlertDialog(
            backgroundColor: AppColors.surfaceFor(ctx),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: AppColors.borderFor(ctx)),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.warning.withValues(alpha: 0.16)
                        : AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Low Stock Threshold',
                    style: AppTypography.sectionTitle.copyWith(
                      color: AppColors.textPrimaryFor(ctx),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Specify the stock quantity at or below which items are flagged as Low Stock across inventory and KPI counts.',
                    style: AppTypography.bodyMuted.copyWith(
                      color: AppColors.textSecondaryFor(ctx),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'THRESHOLD UNITS (≤ COUNT)',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textMutedFor(ctx),
                      fontSize: 10.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundFor(ctx),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: AppColors.borderFor(ctx),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            style: AppTypography.mono.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryFor(ctx),
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: 'e.g. 10',
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val.trim());
                              if (parsed != null && parsed >= 0) {
                                setDialogState(() {
                                  selectedValue = parsed;
                                });
                              }
                            },
                          ),
                        ),
                        Text(
                          'Units',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMutedFor(ctx),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'QUICK PRESETS',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textMutedFor(ctx),
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [5, 10, 15, 20, 30].map((preset) {
                      final isSelected = selectedValue == preset;
                      return InkWell(
                        onTap: () => updateValue(preset),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white10
                                    : AppColors.surfaceAltFor(ctx)),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '$preset units',
                            style: AppTypography.body.copyWith(
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimaryFor(ctx),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondaryFor(ctx),
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () {
                  final parsed =
                      int.tryParse(controller.text.trim()) ?? selectedValue;
                  if (parsed >= 0) {
                    ref
                        .read(inventoryLowStockThresholdProvider.notifier)
                        .state = parsed;
                  }
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  'Save Threshold',
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

// ── Loading skeleton ─────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundFor(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderFor(context)),
        boxShadow: AppColors.cardShadowFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 80,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: AppTypography.label
                  .copyWith(color: AppColors.textMutedFor(context))),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _SkeletonCard(label: 'Total SCM Codes')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: _SkeletonCard(label: 'Net Inventory Worth')),
        SizedBox(width: AppSpacing.md),
        Expanded(child: _SkeletonCard(label: 'Low Stock')),
      ],
    );
  }
}
