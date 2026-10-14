import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/categories_table.dart';
import '../widgets/category_form_card.dart';

class CategoryMasterScreen extends StatelessWidget {
  const CategoryMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoriesTable(),
          SizedBox(height: AppSpacing.lg),
          CategoryFormCard(),
        ],
      ),
    );
  }
}
