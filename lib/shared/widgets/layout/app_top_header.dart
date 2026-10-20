import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/font_scale_provider.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/dashboard/data/dashboard_providers.dart';
import '../../../features/inventory/data/inventory_providers.dart';
import '../../../features/masters/data/masters_providers.dart';
import '../../../features/purchase/data/purchase_providers.dart';
import '../../../features/reports/data/brandwise_report_provider.dart';
import '../../../features/reports/data/counter_brandwise_report_provider.dart';
import '../../../features/reports/data/reports_providers.dart';
import '../../../features/sales/data/sales_providers.dart';
// import '../../../features/sync/data/sync_providers.dart';

/// A docked Apple macOS window toolbar that connects flush with the sidebar.
///
/// Features:
///   • Docked 60px height with continuous 1px bottom border.
///   • Zero duplicates (no redundant avatar, logout, or date chips).
///   • High-utility tools: Quick Calculator, Notes, POS Shortcuts Dialog, Theme Switcher.
///   • Universal Screen Refresh button to reload active screen data.
class AppTopHeader extends ConsumerWidget {
  const AppTopHeader({
    super.key,
    required this.moduleTitle,
    required this.moduleShortcutLabel,
  });

  final String moduleTitle;
  final String moduleShortcutLabel;

  void _launchApp(String appName) {
    try {
      if (Platform.isMacOS) {
        Process.run('open', ['-a', appName]);
      }
    } catch (_) {}
  }

  void _showShortcutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _KeyboardShortcutsDialog(),
    );
  }

  void _handleRefresh(BuildContext context, WidgetRef ref) {
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(inventoryOverviewProvider);
    ref.invalidate(inventoryListProvider);
    ref.invalidate(filteredInventoryOverviewProvider);
    ref.invalidate(salesReportProvider);
    ref.invalidate(brandwiseReportProvider);
    ref.invalidate(counterBrandwiseReportProvider);
    ref.invalidate(categoriesListProvider);
    ref.invalidate(suppliersListProvider);
    ref.invalidate(manufacturersListProvider);
    ref.invalidate(materialsListProvider);
    ref.invalidate(packingsListProvider);
    ref.invalidate(materialLookupCacheProvider);
    ref.invalidate(todaysBillsProvider);
    ref.invalidate(purchaseBillsListProvider);

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Data refreshed successfully', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync Center commented out for offline-first MVP
    // final syncOverviewAsync = ref.watch(syncOverviewProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final headerBg = isDark
        ? const Color(0xFF151720)
        : const Color(0xFFF6F6F9);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderFor(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // ── Module Title & Shortcut Tag ─────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                moduleTitle,
                style: AppTypography.h2.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildShortcutPill(context, moduleShortcutLabel, isDark),
            ],
          ),

          const Spacer(),

          // ── Universal Screen Refresh Action ─────────────────────────────
          _HeaderIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh Screen Data',
            onTap: () => _handleRefresh(context, ref),
          ),

          // ── Sync & Connectivity Status Pill (Commented out for offline MVP) ─
          // _buildSyncStatusPill(context, syncOverviewAsync, isDark),

          const SizedBox(width: 12),
          _divider(context),
          const SizedBox(width: 12),

          // ── Quick POS Utilities ────────────────────────────────────────
          _HeaderIconButton(
            icon: Icons.calculate_outlined,
            tooltip: 'Open Calculator (macOS)',
            onTap: () => _launchApp('Calculator'),
          ),
          const SizedBox(width: 6),
          _HeaderIconButton(
            icon: Icons.edit_note_rounded,
            tooltip: 'Quick Notes (macOS)',
            onTap: () => _launchApp('Notes'),
          ),
          const SizedBox(width: 6),
          _HeaderIconButton(
            icon: Icons.keyboard_outlined,
            tooltip: 'Keyboard Shortcuts (F1–F12)',
            onTap: () => _showShortcutsDialog(context),
          ),
          const SizedBox(width: 8),
          const _FontSizePillStepper(),
          const SizedBox(width: 8),
          _HeaderIconButton(
            icon: themeMode == ThemeMode.dark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onTap: () => ref.read(appThemeModeProvider.notifier).state =
                isDark ? ThemeMode.light : ThemeMode.dark,
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutPill(
    BuildContext context,
    String label,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.22)
            : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: isDark ? const Color(0xFFD0C7FF) : AppColors.primary,
        ),
      ),
    );
  }

  // Sync Center pill commented out for offline MVP
  // Widget _buildSyncStatusPill(...) { ... }

  Widget _divider(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      color: AppColors.borderFor(context),
    );
  }
}

// ─── Reusable Header Icon Button ─────────────────────────────────────────────

class _HeaderIconButton extends StatefulWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 350),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hovered
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              size: 17,
              color: _hovered
                  ? AppColors.textPrimaryFor(context)
                  : AppColors.textSecondaryFor(context),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Keyboard Shortcuts Modal ────────────────────────────────────────────────

class _KeyboardShortcutsDialog extends StatelessWidget {
  const _KeyboardShortcutsDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1B1E28) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.keyboard_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'POS Keyboard Shortcuts',
                            style: AppTypography.h2.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryFor(context),
                            ),
                          ),
                          Text(
                            'Hardware function keys for high-speed operation',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryFor(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(height: 1, color: AppColors.borderFor(context)),
              const SizedBox(height: 16),

              // Two columns: Global Nav vs Billing Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Global Screen Navigation
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SCREEN NAVIGATION',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.textMutedFor(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _shortcutRow(context, 'F1', 'Dashboard'),
                        _shortcutRow(context, 'F2', 'Purchase Bill'),
                        _shortcutRow(context, 'F3', 'Sales Bill'),
                        _shortcutRow(context, 'F4', 'Material Master'),
                        _shortcutRow(context, 'F5', 'Inventory'),
                        _shortcutRow(context, 'F6', 'Daily Sale Report'),
                        _shortcutRow(context, 'F7', 'Supplier Master'),
                        _shortcutRow(context, 'F8', 'Sales Return'),
                        _shortcutRow(context, 'F9', 'All Masters'),
                        _shortcutRow(context, 'F10', 'Brandwise Report'),
                        _shortcutRow(context, 'F11', 'Category Master'),
                        _shortcutRow(context, 'F12', 'Sync Center'),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),
                  Container(
                    width: 1,
                    height: 260,
                    color: AppColors.borderFor(context),
                  ),
                  const SizedBox(width: 24),

                  // In-Billing Shortcuts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SALES BILLING ACTIONS',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.textMutedFor(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _shortcutRow(context, 'F1', 'Focus Barcode Scanner'),
                        _shortcutRow(context, 'F4', 'Focus Quantity Field'),
                        _shortcutRow(context, 'F6', 'Hold Current Bill'),
                        _shortcutRow(context, 'F8', 'Settle / Complete Sale'),
                        _shortcutRow(context, 'Esc', 'Clear / Cancel Action'),
                        const SizedBox(height: 24),
                        Text(
                          'PURCHASE BILLING',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.textMutedFor(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _shortcutRow(context, 'F8', 'Save / Complete Bill'),
                        _shortcutRow(context, 'Esc', 'Cancel / Back'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shortcutRow(BuildContext context, String key, String label) {
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFF1F1F6),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFE0E0EA),
                width: 0.8,
              ),
            ),
            child: Text(
              key,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryFor(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryFor(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Minimal macOS Segmented Pill Stepper (Hover Expand/Collapse) ───────────

class _FontSizePillStepper extends ConsumerStatefulWidget {
  const _FontSizePillStepper();

  @override
  ConsumerState<_FontSizePillStepper> createState() =>
      _FontSizePillStepperState();
}

class _FontSizePillStepperState extends ConsumerState<_FontSizePillStepper> {
  bool _isHovered = false;
  bool _isToggled = false;

  bool get _isExpanded => _isHovered || _isToggled;

  @override
  Widget build(BuildContext context) {
    final fontScale = ref.watch(appFontScaleProvider);
    final notifier = ref.read(appFontScaleProvider.notifier);
    final isDark = AppColors.isDark(context);
    final isScaled = (fontScale - 1.00).abs() > 0.01;

    final canDecrease =
        fontScale > FontScaleNotifier.supportedScales.first + 0.01;
    final canIncrease =
        fontScale < FontScaleNotifier.supportedScales.last - 0.01;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isToggled = false;
      }),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 28,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _isExpanded
                ? (isDark ? const Color(0xFF1B1E29) : const Color(0xFFEBEBF0))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isExpanded
                  ? (isScaled
                      ? AppColors.primary.withValues(alpha: isDark ? 0.45 : 0.4)
                      : AppColors.borderFor(context))
                  : Colors.transparent,
              width: 0.8,
            ),
          ),
          child: _isExpanded
              ? Row(
                  key: const ValueKey('expanded'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Decrease button
                    _PillSegmentButton(
                      tooltip: canDecrease
                          ? 'Decrease font size'
                          : 'Minimum font size reached',
                      enabled: canDecrease,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(5),
                      ),
                      onTap: canDecrease ? () => notifier.decrease() : null,
                      child: Text(
                        'A⁻',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: canDecrease
                              ? AppColors.textPrimaryFor(context)
                              : AppColors.textMutedFor(context)
                                  .withValues(alpha: 0.35),
                        ),
                      ),
                    ),

                    _divider(context),

                    // Percentage display & reset action
                    _PillSegmentButton(
                      tooltip: isScaled
                          ? 'Click to reset to 100%'
                          : 'Standard font size (100%)',
                      enabled: isScaled,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      onTap: isScaled ? () => notifier.reset() : null,
                      child: Text(
                        '${(fontScale * 100).round()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isScaled ? FontWeight.w700 : FontWeight.w600,
                          color: isScaled
                              ? AppColors.primary
                              : AppColors.textSecondaryFor(context),
                        ),
                      ),
                    ),

                    _divider(context),

                    // Increase button
                    _PillSegmentButton(
                      tooltip: canIncrease
                          ? 'Increase font size'
                          : 'Maximum font size reached',
                      enabled: canIncrease,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(5),
                      ),
                      onTap: canIncrease ? () => notifier.increase() : null,
                      child: Text(
                        'A⁺',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: canIncrease
                              ? AppColors.textPrimaryFor(context)
                              : AppColors.textMutedFor(context)
                                  .withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ],
                )
              : Tooltip(
                  message:
                      'Text Size (${(fontScale * 100).round()}%) • Hover to adjust',
                  waitDuration: const Duration(milliseconds: 300),
                  child: GestureDetector(
                    onTap: () => setState(() => _isToggled = true),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      key: const ValueKey('collapsed'),
                      width: 32,
                      height: 28,
                      child: Center(
                        child: Icon(
                          Icons.format_size_rounded,
                          size: 17,
                          color: isScaled
                              ? AppColors.primary
                              : AppColors.textSecondaryFor(context),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      width: 1,
      height: 14,
      color: AppColors.borderFor(context),
    );
  }
}

class _PillSegmentButton extends StatefulWidget {
  const _PillSegmentButton({
    required this.child,
    required this.tooltip,
    this.onTap,
    this.enabled = true,
    this.borderRadius = BorderRadius.zero,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });

  final Widget child;
  final String tooltip;
  final VoidCallback? onTap;
  final bool enabled;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  @override
  State<_PillSegmentButton> createState() => _PillSegmentButtonState();
}

class _PillSegmentButtonState extends State<_PillSegmentButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: MouseRegion(
        onEnter: (_) {
          if (widget.enabled) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (widget.enabled) setState(() => _hovered = false);
        },
        cursor:
            widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 28,
            padding: widget.padding,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered && widget.enabled
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06))
                  : Colors.transparent,
              borderRadius: widget.borderRadius,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}


