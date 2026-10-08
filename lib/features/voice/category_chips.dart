import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../recordings/voice_style.dart';

/// Horizontally scrolling filter: All · Gender · Characters · Sci-fi · Effects.
/// `null` = All. Selection uses fill + check icon + weight (not colour alone).
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.counts,
  });

  final VoiceCategory? selected;
  final ValueChanged<VoiceCategory?> onChanged;

  /// Number of voices per category, shown as a small count.
  final Map<VoiceCategory?, int> counts;

  @override
  Widget build(BuildContext context) {
    final items = <VoiceCategory?>[null, ...VoiceCategory.values];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = items[i];
          return Center(
            child: _Chip(
              label: cat?.label ?? 'All',
              count: counts[cat] ?? 0,
              selected: selected == cat,
              onTap: () {
                if (selected == cat) return;
                HapticFeedback.selectionClick();
                onChanged(cat);
              },
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = context.reduceMotion ? Duration.zero : AppMotion.medium;
    final fg = selected ? c.onPrimary : c.textPrimary;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count voices',
      excludeSemantics: true,
      child: Pressable(
        scale: 0.94,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: d,
            curve: AppMotion.enter,
            height: 36,
            padding: EdgeInsets.only(left: selected ? 10 : 14, right: 14),
            decoration: BoxDecoration(
              color: selected ? c.primary : c.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: selected ? c.primary : c.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: d,
                  curve: AppMotion.enter,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(LucideIcons.check, size: 16, color: fg),
                        )
                      : const SizedBox.shrink(),
                ),
                Text(
                  label,
                  style: AppText.label.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: AppText.caption.copyWith(
                    color: selected
                        ? c.onPrimary.withValues(alpha: 0.75)
                        : c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
