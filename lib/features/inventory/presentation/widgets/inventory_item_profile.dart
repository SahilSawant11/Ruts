import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/inventory_overview_item.dart';

class InventoryItemProfile extends StatelessWidget {
  const InventoryItemProfile({
    super.key,
    required this.item,
    this.size = 38,
  });

  final InventoryOverviewItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(item);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: spec.border),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              spec.icon,
              size: spec.iconSize,
              color: spec.foreground,
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
              padding: spec.badge.isEmpty ? const EdgeInsets.all(0) : const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: spec.foreground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.backgroundFor(context), width: 1.2),
              ),
              child: spec.badge.isEmpty
                  ? const SizedBox(width: 10, height: 10)
                  : Text(
                      spec.badge,
                      textAlign: TextAlign.center,
                      style: AppTypography.mono.copyWith(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  _ProfileSpec _specFor(InventoryOverviewItem item) {
    final packing = item.packing.toLowerCase();
    final category = item.category.toLowerCase();

    if (category.contains('beer')) {
      if (packing.contains('can')) {
        return const _ProfileSpec(
          icon: Icons.local_drink_rounded,
          badge: '',
          foreground: AppColors.chartBlue,
          background: Color(0xFFEAF6FE),
          border: Color(0xFFC8E7FB),
          iconSize: 20,
        );
      }
      return const _ProfileSpec(
        icon: Icons.liquor_rounded,
        badge: '',
        foreground: AppColors.warning,
        background: AppColors.warningSoft,
        border: Color(0xFFF4D6A8),
        iconSize: 20,
      );
    }

    if (category.contains('whisk')) {
      return _whiskySpec(packing);
    }

    if (category.contains('rum')) {
      return _spiritSpec(
        packing,
        foreground: AppColors.chartTeal,
        background: const Color(0xFFE8FAF7),
        border: const Color(0xFFBEEFE6),
      );
    }

    if (category.contains('vodka')) {
      return _spiritSpec(
        packing,
        foreground: AppColors.info,
        background: const Color(0xFFEAF3FF),
        border: const Color(0xFFC9DCFF),
      );
    }

    if (category.contains('wine')) {
      return const _ProfileSpec(
        icon: Icons.wine_bar_rounded,
        badge: 'WNE',
        foreground: AppColors.danger,
        background: AppColors.dangerSoft,
        border: Color(0xFFF2C8CA),
        iconSize: 20,
      );
    }

    return _spiritSpec(
      packing,
      foreground: AppColors.primary,
      background: AppColors.primarySoft,
      border: const Color(0xFFD8D0FB),
    );
  }

  _ProfileSpec _whiskySpec(String packing) {
    final ml = _extractMl(packing);
    if (ml != null && ml <= 100) {
      return const _ProfileSpec(
        icon: Icons.local_bar_rounded,
        badge: '90',
        foreground: AppColors.primary,
        background: AppColors.primarySoft,
        border: Color(0xFFD8D0FB),
        iconSize: 17,
      );
    }
    if (ml != null && ml <= 200) {
      return const _ProfileSpec(
        icon: Icons.local_bar_rounded,
        badge: '180',
        foreground: AppColors.primary,
        background: AppColors.primarySoft,
        border: Color(0xFFD8D0FB),
        iconSize: 20,
      );
    }
    if (ml != null && ml <= 400) {
      return const _ProfileSpec(
        icon: Icons.sports_bar_rounded,
        badge: '375',
        foreground: AppColors.primary,
        background: AppColors.primarySoft,
        border: Color(0xFFD8D0FB),
        iconSize: 19,
      );
    }
    return const _ProfileSpec(
      icon: Icons.liquor_rounded,
      badge: '750',
      foreground: AppColors.primary,
      background: AppColors.primarySoft,
      border: Color(0xFFD8D0FB),
      iconSize: 20,
    );
  }

  _ProfileSpec _spiritSpec(
    String packing, {
    required Color foreground,
    required Color background,
    required Color border,
  }) {
    final ml = _extractMl(packing);
    if (ml != null && ml <= 100) {
      return _ProfileSpec(
        icon: Icons.local_bar_rounded,
        badge: '${ml.round()}',
        foreground: foreground,
        background: background,
        border: border,
        iconSize: 17,
      );
    }
    if (ml != null && ml <= 200) {
      return _ProfileSpec(
        icon: Icons.local_bar_rounded,
        badge: '${ml.round()}',
        foreground: foreground,
        background: background,
        border: border,
        iconSize: 20,
      );
    }
    if (ml != null && ml <= 400) {
      return _ProfileSpec(
        icon: Icons.sports_bar_rounded,
        badge: '${ml.round()}',
        foreground: foreground,
        background: background,
        border: border,
        iconSize: 19,
      );
    }
    return _ProfileSpec(
      icon: Icons.liquor_rounded,
      badge: ml == null ? 'BTL' : '${ml.round()}',
      foreground: foreground,
      background: background,
      border: border,
      iconSize: 20,
    );
  }

  double? _extractMl(String packing) {
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*ml').firstMatch(packing);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }
}

class _ProfileSpec {
  const _ProfileSpec({
    required this.icon,
    required this.badge,
    required this.foreground,
    required this.background,
    required this.border,
    required this.iconSize,
  });

  final IconData icon;
  final String badge;
  final Color foreground;
  final Color background;
  final Color border;
  final double iconSize;
}
