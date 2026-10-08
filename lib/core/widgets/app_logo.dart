import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Figma "App logo": 104dp rounded square (radius 30) with 5 level bars.
/// [progress] 0→1 grows the bars in one after another (used by Splash).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.progress = 1});

  final double progress;

  static const List<double> _heights = [20, 40, 56, 32, 44];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final n = _heights.length;
    return ExcludeSemantics(
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Builder(builder: (_) {
                final start = i / n * 0.5;
                final t = ((progress - start) / 0.5).clamp(0.0, 1.0);
                final h = 8 + (_heights[i] - 8) * Curves.easeOutBack.transform(t);
                return Container(
                  width: 8,
                  height: h.clamp(8.0, 64.0),
                  decoration: BoxDecoration(
                    color: c.onPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
