import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/suppliers_table.dart';
import '../widgets/supplier_form_card.dart';

class SupplierMasterScreen extends StatelessWidget {
  const SupplierMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SuppliersTable(),
          SizedBox(height: AppSpacing.lg),
          SupplierFormCard(),
        ],
      ),
    );
  }
}
