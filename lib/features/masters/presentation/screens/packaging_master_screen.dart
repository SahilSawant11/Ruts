import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/packaging_form_card.dart';
import '../widgets/packagings_table.dart';

/// Packaging Master Screen:
/// Features an Apple-style Side-by-Side Split View on desktop screens
/// (Directory on the left, Inspector on the right) with seamless
/// scrolling fallback for narrower viewports.
class PackagingMasterScreen extends StatelessWidget {
  const PackagingMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSplit = constraints.maxWidth >= 960;

        if (isSplit) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 58,
                  child: PackagingsTable(isSplitView: true),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 42,
                  child: PackagingFormCard(isSplitView: true),
                ),
              ],
            ),
          );
        }

        return const SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PackagingsTable(isSplitView: false),
              SizedBox(height: AppSpacing.md),
              PackagingFormCard(isSplitView: false),
            ],
          ),
        );
      },
    );
  }
}
