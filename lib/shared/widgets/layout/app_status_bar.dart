import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// POS hardware keyboard command bar docked flush to the bottom of the shell.
///
/// Features:
///   • Exact 44px height aligning with the sidebar footer to form one continuous bottom line.
///   • Dynamic POS hotkey keycaps tailored to the currently active screen.
///   • Terminal and local database readiness indicators on the right.
///   • Zero repetitive text (clean, functional, macOS-native).
class AppStatusBar extends ConsumerWidget {
  const AppStatusBar({
    super.key,
    required this.moduleName,
    this.branchIndex = 0,
  });

  final String moduleName;
  final int branchIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);

    final bg = isDark
        ? const Color(0xFF151720)
        : const Color(0xFFF6F6F9);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showTerminalInfo = width >= 900;
        final showVersion = width >= 1150;

        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              top: BorderSide(
                color: AppColors.borderFor(context),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // ── Dynamic POS Hotkeys for Active Screen ────────────────────
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _buildHotkeysForBranch(branchIndex),
                  ),
                ),
              ),

              // ── Right: Terminal & Readiness Status ───────────────────────
              if (showTerminalInfo) ...[
                const SizedBox(width: AppSpacing.md),
                _divider(context),
                const SizedBox(width: AppSpacing.md),
                _statusDot(),
                const SizedBox(width: 6),
                Text(
                  'Counter #1 · Ready',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ],
              if (showVersion) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '· v8.4',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMutedFor(context),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildHotkeysForBranch(int index) {
    const space = SizedBox(width: 6);

    switch (index) {
      // Branch 1: Sales Billing
      case 1:
        return const [
          _HotkeyPill(keyLabel: 'F1', actionLabel: 'Scan Item'),
          space,
          _HotkeyPill(keyLabel: 'F4', actionLabel: 'Qty'),
          space,
          _HotkeyPill(keyLabel: 'F6', actionLabel: 'Hold Bill'),
          space,
          _HotkeyPill(keyLabel: 'F8', actionLabel: 'Settle Bill', isAccent: true),
          space,
          _HotkeyPill(keyLabel: 'Esc', actionLabel: 'Clear'),
        ];

      // Branch 2: Purchase Billing
      case 2:
        return const [
          _HotkeyPill(keyLabel: 'F8', actionLabel: 'Save Purchase', isAccent: true),
          space,
          _HotkeyPill(keyLabel: 'F3', actionLabel: 'Sales Bill'),
          space,
          _HotkeyPill(keyLabel: 'Esc', actionLabel: 'Cancel'),
        ];

      // Branch 12: Sales Return
      case 12:
        return const [
          _HotkeyPill(keyLabel: 'F8', actionLabel: 'Settle Return', isAccent: true),
          space,
          _HotkeyPill(keyLabel: 'F3', actionLabel: 'Sales Bill'),
          space,
          _HotkeyPill(keyLabel: 'Esc', actionLabel: 'Clear'),
        ];

      // Branch 13: Purchase Return
      case 13:
        return const [
          _HotkeyPill(keyLabel: 'F8', actionLabel: 'Complete Return', isAccent: true),
          space,
          _HotkeyPill(keyLabel: 'F2', actionLabel: 'Purchase Bill'),
          space,
          _HotkeyPill(keyLabel: 'Esc', actionLabel: 'Clear'),
        ];

      // Branch 8: Inventory
      case 8:
        return const [
          _HotkeyPill(keyLabel: 'F5', actionLabel: 'Inventory'),
          space,
          _HotkeyPill(keyLabel: 'F3', actionLabel: 'Sales Bill'),
          space,
          _HotkeyPill(keyLabel: 'F6', actionLabel: 'Daily Sale'),
          space,
          _HotkeyPill(keyLabel: 'F10', actionLabel: 'Brandwise'),
        ];

      // Branches 3, 4, 5, 6, 7, 14: Masters
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
      case 14:
        return const [
          _HotkeyPill(keyLabel: 'F4', actionLabel: 'Material'),
          space,
          _HotkeyPill(keyLabel: 'F11', actionLabel: 'Category'),
          space,
          _HotkeyPill(keyLabel: 'F7', actionLabel: 'Supplier'),
          space,
          _HotkeyPill(keyLabel: 'F9', actionLabel: 'All Masters'),
          space,
          _HotkeyPill(keyLabel: 'F3', actionLabel: 'Sales Bill'),
        ];

      // Branches 9, 10: Reports
      case 9:
      case 10:
        return const [
          _HotkeyPill(keyLabel: 'F6', actionLabel: 'Daily Sale'),
          space,
          _HotkeyPill(keyLabel: 'F10', actionLabel: 'Brandwise'),
          space,
          _HotkeyPill(keyLabel: 'F3', actionLabel: 'Sales Bill'),
          space,
          _HotkeyPill(keyLabel: 'F5', actionLabel: 'Inventory'),
        ];

      // Branch 11: Sync Center
      case 11:
        return const [
          _HotkeyPill(keyLabel: 'F12', actionLabel: 'Sync Center'),
          space,
          _HotkeyPill(keyLabel: 'F3', actionLabel: 'Sales Bill'),
          space,
          _HotkeyPill(keyLabel: 'F1', actionLabel: 'Dashboard'),
        ];

      // Branch 0: Dashboard (Default)
      case 0:
      default:
        return const [
          _HotkeyPill(keyLabel: 'F1', actionLabel: 'Dashboard'),
          space,
          _HotkeyPill(keyLabel: 'F3', actionLabel: 'Sales Bill'),
          space,
          _HotkeyPill(keyLabel: 'F2', actionLabel: 'Purchase Bill'),
          space,
          _HotkeyPill(keyLabel: 'F5', actionLabel: 'Inventory'),
          space,
          _HotkeyPill(keyLabel: 'F12', actionLabel: 'Sync Center'),
        ];
    }
  }

  Widget _divider(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      color: AppColors.borderFor(context),
    );
  }

  Widget _statusDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─── POS Hotkey Pill Keycap ──────────────────────────────────────────────────

class _HotkeyPill extends StatelessWidget {
  const _HotkeyPill({
    required this.keyLabel,
    required this.actionLabel,
    this.isAccent = false,
  });

  final String keyLabel;
  final String actionLabel;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final bg = isAccent
        ? (isDark
            ? AppColors.primary.withValues(alpha: 0.28)
            : AppColors.primarySoft)
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.035));

    final borderColor = isAccent
        ? (isDark
            ? AppColors.primary.withValues(alpha: 0.45)
            : AppColors.primary.withValues(alpha: 0.30))
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06));

    final keycapBg = isAccent
        ? (isDark
            ? AppColors.primary.withValues(alpha: 0.40)
            : Colors.white)
        : (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : const Color(0xFFE9E9F0));

    final keycapText = isAccent
        ? (isDark ? const Color(0xFFDCD4FF) : AppColors.primary)
        : (isDark ? const Color(0xFFBAC2D6) : const Color(0xFF4A4A58));

    final actionText = isAccent
        ? (isDark ? const Color(0xFFDCD4FF) : AppColors.primary)
        : (isDark ? const Color(0xFF8B93A7) : const Color(0xFF656575));

    return Container(
      height: 25,
      padding: const EdgeInsets.fromLTRB(4, 2, 7, 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
            decoration: BoxDecoration(
              color: keycapBg,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
                width: 0.5,
              ),
              boxShadow: isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 1,
                        offset: Offset(0, 0.8),
                      ),
                    ],
            ),
            child: Text(
              keyLabel,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: keycapText,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            actionLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isAccent ? FontWeight.w700 : FontWeight.w500,
              color: actionText,
            ),
          ),
        ],
      ),
    );
  }
}

