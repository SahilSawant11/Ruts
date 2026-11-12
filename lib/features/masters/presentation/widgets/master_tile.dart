import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../shared/widgets/badges/tag_pill.dart';
import '../../../../shared/widgets/data/fact_card.dart';

/// A masters hub tile: a fact card whose figure is the record count
/// ("3" suppliers), or the subtitle when there is no count.
class MasterTile extends StatelessWidget {
  const MasterTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.count,
    this.unit,
    this.onTap,
    this.comingSoon = false,
  });

  final AppIconData icon;
  final String title;
  final String subtitle;

  /// Shown as the big figure, e.g. '8'. Null shows [subtitle] instead.
  final String? count;
  final String? unit;
  final VoidCallback? onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final card = count != null
        ? FactCard(
            icon: icon,
            title: title,
            value: count!,
            unit: unit,
            onTap: comingSoon ? null : onTap,
            badge: comingSoon ? const TagPill(label: 'SOON', tone: TagPillTone.neutral) : null,
          )
        : FactCard(
            icon: icon,
            title: title,
            value: '',
            caption: subtitle,
            onTap: comingSoon ? null : onTap,
            badge: comingSoon ? const TagPill(label: 'SOON', tone: TagPillTone.neutral) : null,
          );
    return Opacity(opacity: comingSoon ? 0.5 : 1, child: card);
  }
}
