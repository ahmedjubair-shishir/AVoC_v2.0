import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Figma "Chip": compact, non-interactive status label.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.leading,
    this.tonal = false,
  });

  final String label;
  final Widget? leading;

  /// Tonal = primary/container fill (e.g. "Robot voice").
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: tonal ? c.primaryContainer : c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Text(
            label,
            style: AppText.label.copyWith(
              color: tonal ? c.onPrimaryContainer : c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma "Banner/Info": inline message in primary/container.
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: c.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppText.body.copyWith(color: c.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
