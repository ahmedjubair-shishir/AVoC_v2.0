import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dashed_border_box.dart';
import '../../../core/widgets/icon_badge.dart';

/// Shown in Home › Recent and History when there are no recordings (node 4:228).
class RecentEmptyState extends StatelessWidget {
  const RecentEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DashedBorderBox(
      color: c.surface,
      borderColor: c.border,
      radius: AppRadius.lg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const IconBadge(icon: LucideIcons.mic),
            const SizedBox(height: 20),
            Text(
              'No recordings yet',
              textAlign: TextAlign.center,
              style: AppText.title.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpace.s8),
            Text(
              'Your recordings will appear here.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
