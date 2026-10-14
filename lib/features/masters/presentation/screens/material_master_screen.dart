import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/material_form_card.dart';
import '../widgets/materials_table.dart';

class MaterialMasterScreen extends StatelessWidget {
  const MaterialMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MaterialsTable(),
          SizedBox(height: AppSpacing.lg),
          MaterialFormCard(),
        ],
      ),
    );
  }
}
