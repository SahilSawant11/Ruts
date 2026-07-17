import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  _BranchMeta('Dashboard', 'Home', 'Dashboard'),
  _BranchMeta('Sale', 'F3 · Sales Bill', 'Sale'),
  _BranchMeta('Purchase', 'F2 · Purchase Bill', 'Purchase'),
  _BranchMeta('Supplier', 'Master · Supplier', 'Supplier'),
  _BranchMeta('Material', 'Master · Material', 'Material'),
  _BranchMeta('Masters', 'All Masters', 'Masters'),
  _BranchMeta('Inventory', 'Stock overview', 'Inventory'),
  _BranchMeta('Reports', 'Analysis', 'Reports'),
];

/// The persistent app chrome: fixed left sidebar, fixed top header,
/// a swappable content area (the active branch's navigator), and a
/// fixed bottom status bar.
///
/// This widget is built ONCE by the StatefulShellRoute in router.dart
/// and stays alive across navigation — only [navigationShell]'s inner
/// content swaps, which is what stops the whole screen (sidebar
/// included) from rebuilding on every nav, and lets each tab keep its
/// own state (e.g. the Sales cart) when you switch away and back.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final meta = _branchMeta[navigationShell.currentIndex];

    return Scaffold(
      body: Row(
        children: [
          const AppSidebar(),
          Expanded(
            child: Column(
              children: [
                AppTopHeader(moduleTitle: meta.title, moduleShortcutLabel: meta.shortcut),
                Expanded(child: navigationShell),
                AppStatusBar(moduleName: meta.statusName),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
