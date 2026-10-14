import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/packaging_form_card.dart';
import '../widgets/packagings_table.dart';

class PackagingMasterScreen extends StatelessWidget {
  const PackagingMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PackagingsTable(),
          SizedBox(height: AppSpacing.lg),
          PackagingFormCard(),
        ],
      ),
    );
  }
}
