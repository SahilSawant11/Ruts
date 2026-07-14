import 'package:flutter/material.dart';
import 'app_sidebar.dart';
import 'app_status_bar.dart';
import 'app_top_header.dart';

/// The desktop shell used by every module screen: fixed left sidebar,
/// fixed top header, a scrollable content area, and a fixed bottom
/// status bar. Screens only need to provide their body content.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.moduleTitle,
    required this.moduleShortcutLabel,
    required this.body,
    String? statusModuleName,
  }) : statusModuleName = statusModuleName ?? moduleTitle;

  final String moduleTitle;
  final String moduleShortcutLabel;
  final Widget body;
  final String statusModuleName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const AppSidebar(),
          Expanded(
            child: Column(
              children: [
                AppTopHeader(
                  moduleTitle: moduleTitle,
                  moduleShortcutLabel: moduleShortcutLabel,
                ),
                Expanded(child: body),
                AppStatusBar(moduleName: statusModuleName),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
