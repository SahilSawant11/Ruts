import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart' show kBranchRoutes;
import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/dashboard/data/dashboard_providers.dart';
import 'app_sidebar.dart';
import 'app_status_bar.dart';
import 'app_top_header.dart';

/// Per-branch chrome text, in the same order as the branches defined
/// in router.dart. Keeping this alongside the shell (rather than
/// scattered across each screen) means adding a new tab is a
/// one-line change here + one branch in the router.
class _BranchMeta {
  const _BranchMeta(this.title, this.shortcut, this.statusName);
  final String title;
  final String shortcut;
  final String statusName;
}

const _branchMeta = [
  _BranchMeta('Dashboard', 'F1 · Dashboard', 'Dashboard'),
  _BranchMeta('Sale', 'F3 · Sales Bill', 'Sale'),
  _BranchMeta('Purchase', 'F2 · Purchase Bill', 'Purchase'),
  _BranchMeta('Supplier', 'F7 · Supplier Master', 'Supplier'),
  _BranchMeta('Material', 'F4 · Material Master', 'Material'),
  _BranchMeta('Category', 'F11 · Category Master', 'Category'),
  _BranchMeta('Manufacturer', 'Master · Manufacturer', 'Manufacturer'),
  _BranchMeta('Masters', 'F9 · All Masters', 'Masters'),
  _BranchMeta('Inventory', 'F5 · Inventory', 'Inventory'),
  _BranchMeta('SCM Daily Sale', 'F6 · SCM Daily Sale', 'SCM Daily Sale Report'),
  _BranchMeta('Brandwise Report', 'F10 · Brandwise', 'Brandwise'),
  _BranchMeta('Sync Center', 'F12 · Sync Center', 'Sync'),
  _BranchMeta('Sales Return', 'F8 · Sales Return', 'Sales Return'),
  _BranchMeta('Purchase Return', 'Purchase · Return', 'Purchase Return'),
  _BranchMeta('Packaging', 'Master · Packaging', 'Packaging'),
  _BranchMeta('License Holder', 'Master · License Holder', 'License Holder'),
  _BranchMeta('Settings', 'Settings · Backup & Users', 'Settings'),
];

/// The persistent app chrome: fixed left sidebar, fixed top header,
/// a swappable content area (the active branch's navigator), and a
/// fixed bottom status bar.
///
/// Listens to global hardware function keys (F1 - F12) to immediately switch
/// between screens from anywhere in the application, even when input fields
/// are focused.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex == 0 &&
        oldWidget.navigationShell.currentIndex != 0) {
      ref.invalidate(dashboardSummaryProvider);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    super.dispose();
  }

  static bool _matches(KeyEvent event, LogicalKeyboardKey logical, PhysicalKeyboardKey physical) {
    return event.logicalKey == logical || event.physicalKey == physical;
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final currentBranch = widget.navigationShell.currentIndex;

    // When on Sales Screen (branch 1):
    // F1 -> focus Barcode, F4 -> focus Qty, F6 -> Hold Bill, F8 -> Settle / Save Sale, Esc -> Clear
    if (currentBranch == 1) {
      if (_matches(event, LogicalKeyboardKey.f1, PhysicalKeyboardKey.f1) ||
          _matches(event, LogicalKeyboardKey.f4, PhysicalKeyboardKey.f4) ||
          _matches(event, LogicalKeyboardKey.f6, PhysicalKeyboardKey.f6) ||
          _matches(event, LogicalKeyboardKey.f8, PhysicalKeyboardKey.f8) ||
          _matches(event, LogicalKeyboardKey.escape, PhysicalKeyboardKey.escape)) {
        return false;
      }
    }

    // When on Purchase Screen (branch 2):
    // F1 -> search, F2 -> add line item dialog, F4 -> focus Qty, F8 -> save bill, Esc -> clear
    if (currentBranch == 2) {
      if (_matches(event, LogicalKeyboardKey.f1, PhysicalKeyboardKey.f1) ||
          _matches(event, LogicalKeyboardKey.f2, PhysicalKeyboardKey.f2) ||
          _matches(event, LogicalKeyboardKey.f4, PhysicalKeyboardKey.f4) ||
          _matches(event, LogicalKeyboardKey.f8, PhysicalKeyboardKey.f8) ||
          _matches(event, LogicalKeyboardKey.escape, PhysicalKeyboardKey.escape)) {
        return false;
      }
    }

    if (_matches(event, LogicalKeyboardKey.f1, PhysicalKeyboardKey.f1)) {
      ref.invalidate(dashboardSummaryProvider);
      _goBranchIfAllowed(0);
      return true;
    } else if (_matches(event, LogicalKeyboardKey.f2, PhysicalKeyboardKey.f2)) {
      _goBranchIfAllowed(2);
      return true;
    } else if (_matches(event, LogicalKeyboardKey.f3, PhysicalKeyboardKey.f3)) {
      _goBranchIfAllowed(1);
      return true;
    } else if (_matches(event, LogicalKeyboardKey.f4, PhysicalKeyboardKey.f4)) {
      _goBranchIfAllowed(4);
      return true;
    } else if (_matches(event, LogicalKeyboardKey.f5, PhysicalKeyboardKey.f5)) {
      _goBranchIfAllowed(8);
      return true;
    } else if (_matches(event, LogicalKeyboardKey.f6, PhysicalKeyboardKey.f6)) {
      _goBranchIfAllowed(9);
      return true;
    } else if (_matches(event, LogicalKeyboardKey.f7, PhysicalKeyboardKey.f7)) {
      _goBranchIfAllowed(3);
      return true;
    } else if (_matches(event, LogicalKeyboardKey.f8, PhysicalKeyboardKey.f8)) {
      _goBranchIfAllowed(12);
      return true;
    } else if (_matches(event, LogicalKeyboardKey.f9, PhysicalKeyboardKey.f9)) {
      _goBranchIfAllowed(7);
      return true;
    } else if (_matches(event, LogicalKeyboardKey.f10, PhysicalKeyboardKey.f10)) {
      _goBranchIfAllowed(10);
      return true;
    } else if (_matches(event, LogicalKeyboardKey.f11, PhysicalKeyboardKey.f11)) {
      _goBranchIfAllowed(5);
      return true;
    } else if (_matches(event, LogicalKeyboardKey.f12, PhysicalKeyboardKey.f12)) {
      _goBranchIfAllowed(11);
      return true;
    }

    return false;
  }

  /// F-keys bypass the sidebar, so enforce role permissions here too.
  void _goBranchIfAllowed(int index) {
    final user = ref.read(currentUserProvider);
    if (user == null || index >= kBranchRoutes.length || !user.canOpen(kBranchRoutes[index])) return;
    widget.navigationShell.goBranch(index);
  }

  void _triggerBranch(int targetBranch) {
    if (targetBranch == 0) {
      ref.invalidate(dashboardSummaryProvider);
    }
    final currentBranch = widget.navigationShell.currentIndex;
    if (currentBranch == targetBranch) return;
    _goBranchIfAllowed(targetBranch);
  }

  @override
  Widget build(BuildContext context) {
    AppTypography.currentBrightness = Theme.of(context).brightness;
    final meta = _branchMeta[widget.navigationShell.currentIndex];
    final currentBranch = widget.navigationShell.currentIndex;

    final shortcutBindings = <ShortcutActivator, VoidCallback>{
      if (currentBranch != 1 && currentBranch != 2)
        const SingleActivator(LogicalKeyboardKey.f1): () => _triggerBranch(0),
      if (currentBranch != 2)
        const SingleActivator(LogicalKeyboardKey.f2): () => _triggerBranch(2),
      const SingleActivator(LogicalKeyboardKey.f3): () => _triggerBranch(1),
      if (currentBranch != 1 && currentBranch != 2)
        const SingleActivator(LogicalKeyboardKey.f4): () => _triggerBranch(4),
      const SingleActivator(LogicalKeyboardKey.f5): () => _triggerBranch(8),
      if (currentBranch != 1)
        const SingleActivator(LogicalKeyboardKey.f6): () => _triggerBranch(9),
      const SingleActivator(LogicalKeyboardKey.f7): () => _triggerBranch(3),
      if (currentBranch != 1 && currentBranch != 2)
        const SingleActivator(LogicalKeyboardKey.f8): () => _triggerBranch(12),
      const SingleActivator(LogicalKeyboardKey.f9): () => _triggerBranch(7),
      const SingleActivator(LogicalKeyboardKey.f10): () => _triggerBranch(10),
      const SingleActivator(LogicalKeyboardKey.f11): () => _triggerBranch(5),
      const SingleActivator(LogicalKeyboardKey.f12): () => _triggerBranch(11),
    };

    return CallbackShortcuts(
      bindings: shortcutBindings,
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.workspaceCanvasFor(context),
            ),
            child: Row(
              children: [
                const AppSidebar(),
                Expanded(
                  child: Column(
                    children: [
                      AppTopHeader(moduleTitle: meta.title, moduleShortcutLabel: meta.shortcut),
                      Expanded(child: widget.navigationShell),
                      AppStatusBar(
                        moduleName: meta.statusName,
                        branchIndex: widget.navigationShell.currentIndex,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
