import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/manufacturer_form_card.dart';
import '../widgets/manufacturers_table.dart';

class ManufacturerMasterScreen extends StatelessWidget {
  const ManufacturerMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ManufacturersTable(),
          SizedBox(height: AppSpacing.lg),
          ManufacturerFormCard(),
        ],
      ),
    );
  }
}
