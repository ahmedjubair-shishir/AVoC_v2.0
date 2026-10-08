import 'package:flutter/widgets.dart';

import 'motion.dart';

/// Adds a quick "squish" on touch and a springy release.
///
/// It only listens to raw pointer events, so InkWell ripples, buttons and
/// semantics inside keep working unchanged.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.scale = 0.97});

  final Widget child;

  /// Size while held down. 0.97 for cards, ~0.9 for small round buttons.
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && !reduce ? widget.scale : 1,
        duration: _down ? AppMotion.press : AppMotion.release,
        curve: _down ? Curves.easeOut : AppMotion.settle,
        child: widget.child,
      ),
    );
  }
}
