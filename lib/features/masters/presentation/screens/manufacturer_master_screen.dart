import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/manufacturer_form_card.dart';
import '../widgets/manufacturers_table.dart';

/// Manufacturer Master Screen:
/// Features an Apple-style Side-by-Side Split View on desktop screens
/// (Directory on the left, Inspector on the right) with seamless
/// scrolling fallback for narrower viewports.
class ManufacturerMasterScreen extends StatelessWidget {
  const ManufacturerMasterScreen({super.key});

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
                  child: ManufacturersTable(isSplitView: true),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 42,
                  child: ManufacturerFormCard(isSplitView: true),
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
              ManufacturersTable(isSplitView: false),
              SizedBox(height: AppSpacing.md),
              ManufacturerFormCard(isSplitView: false),
            ],
          ),
        );
      },
    );
  }
}
