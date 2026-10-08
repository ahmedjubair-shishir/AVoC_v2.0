import 'package:flutter/material.dart';

/// Decorative waveform (Figma: 30 bars, 5dp wide, radius 3, 40dp tall,
/// spread across the width). Values are 0..1.
class WaveformBars extends StatelessWidget {
  const WaveformBars({
    super.key,
    required this.values,
    required this.color,
    this.height = 40,
    this.minBar = 6,
  });

  final List<double> values;
  final Color color;
  final double height;
  final double minBar;

  @override
  Widget build(BuildContext context) {
    final bars = values.isEmpty ? List<double>.filled(30, 0.3) : values;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final v in bars)
              Container(
                width: 5,
                height: (minBar + (height - minBar) * v).clamp(minBar, height),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
