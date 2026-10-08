import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Figma "Icon badge": decorative circle for empty, permission, success and
/// error states. Small = 64/28 (inside cards), large = 88/40 (full screens).
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.iconColor,
    this.background,
    this.large = false,
  });

  final IconData icon;
  final Color? iconColor;
  final Color? background;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = large ? 88.0 : 64.0;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? c.surfaceRaised,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: large ? 40 : 28, color: iconColor ?? c.textPrimary),
      ),
    );
  }
}
