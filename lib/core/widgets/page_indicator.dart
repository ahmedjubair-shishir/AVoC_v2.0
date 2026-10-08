import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';

/// Figma "Page indicator": active dot is longer (24×8) and primary;
/// others are 8×8 text/secondary. Dots are tappable. a11y "Page X of N".
class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.count,
    required this.index,
    required this.onSelect,
  });

  final int count;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = context.reduceMotion ? Duration.zero : AppMotion.medium;
    return Semantics(
      label: 'Page ${index + 1} of $count',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(i),
              // Extra invisible padding makes the small dots easier to hit.
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                child: AnimatedContainer(
                  duration: d,
                  curve: AppMotion.enter,
                  width: i == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == index ? c.primary : c.textSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
