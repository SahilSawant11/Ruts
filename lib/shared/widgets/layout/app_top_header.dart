import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/sync/data/sync_providers.dart';

/// A docked Apple macOS window toolbar that connects flush with the sidebar.
///
/// Features:
///   • Docked 60px height with continuous 1px bottom border.
///   • Zero duplicates (no redundant avatar, logout, or date chips).
///   • High-utility tools: Quick Calculator, Notes, POS Shortcuts Dialog, Theme Switcher.
///   • Interactive Sync status pill with 1-click drilldown to Sync Center.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncOverviewAsync = ref.watch(syncOverviewProvider);
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

          // ── Sync & Connectivity Status Pill (Clickable) ────────────────
          _buildSyncStatusPill(context, syncOverviewAsync, isDark),

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
          const SizedBox(width: 6),
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

  Widget _buildSyncStatusPill(
    BuildContext context,
    AsyncValue syncOverviewAsync,
    bool isDark,
  ) {
    return syncOverviewAsync.when(
      loading: () => _syncPillContainer(
        context,
        dotColor: AppColors.textMutedFor(context),
        label: 'Checking sync…',
        onTap: () => context.go('/sync'),
        isDark: isDark,
      ),
      error: (_, __) => _syncPillContainer(
        context,
        dotColor: AppColors.warning,
        label: 'Sync diagnostics',
        onTap: () => context.go('/sync'),
        isDark: isDark,
      ),
      data: (overview) {
        if (overview.failed > 0) {
          return _syncPillContainer(
            context,
            dotColor: AppColors.danger,
            label: '${overview.failed} failed',
            onTap: () => context.go('/sync'),
            isDark: isDark,
          );
        }
        if (overview.total > 0) {
          return _syncPillContainer(
            context,
            dotColor: AppColors.warning,
            label: '${overview.total} queued offline',
            onTap: () => context.go('/sync'),
            isDark: isDark,
          );
        }
        return _syncPillContainer(
          context,
          dotColor: AppColors.success,
          label: 'Sync clean',
          onTap: () => context.go('/sync'),
          isDark: isDark,
        );
      },
    );
  }

  Widget _syncPillContainer(
    BuildContext context, {
    required Color dotColor,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Tooltip(
      message: 'Click to open Sync Center',
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

