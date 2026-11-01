import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Represents an icon token that resolves to either a Phosphor glyph (with regular/duotone variants)
/// or a custom SVG asset.
class AppIconData {
  final dynamic regular;
  final dynamic active;
  final String? svgPath;

  const AppIconData.phosphor(this.regular, [this.active]) : svgPath = null;
  const AppIconData.svg(this.svgPath)
      : regular = null,
        active = null;

  bool get isSvg => svgPath != null;
}

/// Unified icon widget for the application.
/// Renders either a Phosphor icon glyph (with regular/active duotone weights) or an SVG.
class AppIcon extends StatelessWidget {
  final AppIconData icon;
  final double? size;
  final Color? color;
  final bool active;

  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 20.0;
    final iconColor = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;

    if (icon.isSvg) {
      return SvgPicture.asset(
        icon.svgPath!,
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    }

    final glyph = (active ? (icon.active ?? icon.regular) : icon.regular) ?? PhosphorIconsRegular.question;
    return PhosphorIcon(
      glyph,
      size: iconSize,
      color: iconColor,
    );
  }
}
