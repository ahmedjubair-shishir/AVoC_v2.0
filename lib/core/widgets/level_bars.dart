import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../motion/motion.dart';

/// Decorative audio level bars (the "waveform" motif in the Figma file).
///
/// They grow in once when shown. Call [LevelBarsState.pulse] (via a GlobalKey)
/// to play a short wave, e.g. when the user taps "Add New".
class LevelBars extends StatefulWidget {
  const LevelBars({
    super.key,
    required this.color,
    this.heights = const [14, 28, 40, 22, 34, 18, 10],
    this.barWidth = 6,
    this.gap = 5,
    this.introDelay = Duration.zero,
  });

  final Color color;
  final List<double> heights;
  final double barWidth;
  final double gap;
  final Duration introDelay;

  @override
  State<LevelBars> createState() => LevelBarsState();
}

class LevelBarsState extends State<LevelBars> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _intro.value = 1;
    } else if (_intro.status == AnimationStatus.dismissed) {
      Future.delayed(widget.introDelay, () {
        if (mounted) _intro.forward();
      });
    }
  }

  /// Plays one short ripple across the bars.
  void pulse() {
    if (context.reduceMotion) return;
    _wave.forward(from: 0);
  }

  @override
  void dispose() {
    _intro.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.heights.length;
    final maxH = widget.heights.reduce(math.max);
    return ExcludeSemantics(
      child: SizedBox(
        height: maxH,
        child: AnimatedBuilder(
          animation: Listenable.merge([_intro, _wave]),
          builder: (_, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) SizedBox(width: widget.gap),
                Container(
                  width: widget.barWidth,
                  height: _heightFor(i, n, maxH),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(widget.barWidth / 2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _heightFor(int i, int n, double maxH) {
    final base = widget.heights[i];
    // Staggered grow-in: each bar starts a little after the previous one.
    final start = i / n * 0.5;
    final t = ((_intro.value - start) / 0.5).clamp(0.0, 1.0);
    final grown = widget.barWidth +
        (base - widget.barWidth) * Curves.easeOutBack.transform(t);
    // Wave: a bump travels left → right and fades out.
    if (!_wave.isAnimating) return grown.clamp(widget.barWidth, maxH);
    final w = _wave.value;
    final phase = (w * (n + 2) - i).clamp(0.0, 2.0) / 2;
    final bump = math.sin(phase * math.pi) * (1 - w) * 0.6;
    return (grown * (1 + bump)).clamp(widget.barWidth, maxH);
  }
}
