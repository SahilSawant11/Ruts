import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/categories_table.dart';
import '../widgets/category_form_card.dart';

/// Category Master Screen:
/// Features an Apple-style Side-by-Side Split View on desktop screens
/// (Directory on the left, Inspector on the right) with seamless
/// scrolling fallback for narrower viewports.
class CategoryMasterScreen extends StatelessWidget {
  const CategoryMasterScreen({super.key});

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
                  child: CategoriesTable(isSplitView: true),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 42,
                  child: CategoryFormCard(isSplitView: true),
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
              CategoriesTable(isSplitView: false),
              SizedBox(height: AppSpacing.md),
              CategoryFormCard(isSplitView: false),
            ],
          ),
        );
      },
    );
  }
}
