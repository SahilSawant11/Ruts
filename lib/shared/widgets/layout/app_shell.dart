import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
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
  _BranchMeta('Reports', 'F6 · Reports', 'Reports'),
  _BranchMeta('Brandwise Report', 'F10 · Brandwise', 'Brandwise'),
  _BranchMeta('Sync Center', 'F12 · Sync Center', 'Sync'),
  _BranchMeta('Sales Return', 'F8 · Sales Return', 'Sales Return'),
  _BranchMeta('Purchase Return', 'Purchase · Return', 'Purchase Return'),
];

/// The persistent app chrome: fixed left sidebar, fixed top header,
/// a swappable content area (the active branch's navigator), and a
/// fixed bottom status bar.
///
/// Listens to global hardware function keys (F1 - F12) to immediately switch
/// between screens from anywhere in the application, even when input fields
/// are focused.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    super.dispose();
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.f1) {
      widget.navigationShell.goBranch(0);
      return true;
    } else if (key == LogicalKeyboardKey.f2) {
      widget.navigationShell.goBranch(2);
      return true;
    } else if (key == LogicalKeyboardKey.f3) {
      widget.navigationShell.goBranch(1);
      return true;
    } else if (key == LogicalKeyboardKey.f4) {
      widget.navigationShell.goBranch(4);
      return true;
    } else if (key == LogicalKeyboardKey.f5) {
      widget.navigationShell.goBranch(8);
      return true;
    } else if (key == LogicalKeyboardKey.f6) {
      widget.navigationShell.goBranch(9);
      return true;
    } else if (key == LogicalKeyboardKey.f7) {
      widget.navigationShell.goBranch(3);
      return true;
    } else if (key == LogicalKeyboardKey.f8) {
      widget.navigationShell.goBranch(12);
      return true;
    } else if (key == LogicalKeyboardKey.f9) {
      widget.navigationShell.goBranch(7);
      return true;
    } else if (key == LogicalKeyboardKey.f10) {
      widget.navigationShell.goBranch(10);
      return true;
    } else if (key == LogicalKeyboardKey.f11) {
      widget.navigationShell.goBranch(5);
      return true;
    } else if (key == LogicalKeyboardKey.f12) {
      widget.navigationShell.goBranch(11);
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final meta = _branchMeta[widget.navigationShell.currentIndex];

    return Scaffold(
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
                  AppStatusBar(moduleName: meta.statusName),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
