import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/license_holders_table.dart';
import '../widgets/license_holder_form_card.dart';

/// License Holder Master Screen:
/// Split view for desktop, vertical fallback for compact screens.
class LicenseHolderMasterScreen extends StatelessWidget {
  const LicenseHolderMasterScreen({super.key});

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
                  child: LicenseHoldersTable(isSplitView: true),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 42,
                  child: LicenseHolderFormCard(isSplitView: true),
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
              LicenseHoldersTable(isSplitView: false),
              SizedBox(height: AppSpacing.md),
              LicenseHolderFormCard(isSplitView: false),
            ],
          ),
        );
      },
    );
  }
}
