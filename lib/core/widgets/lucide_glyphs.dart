import 'package:flutter/widgets.dart';

/// Filled Lucide "play" and "pause" shapes, drawn exactly from Lucide's
/// 24×24 geometry. The Figma file uses filled versions of these icons,
/// which the Lucide icon font (outline only) can't show.
class PlayGlyph extends StatelessWidget {
  const PlayGlyph({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _PlayPainter(color),
      );
}

class PauseGlyph extends StatelessWidget {
  const PauseGlyph({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _PausePainter(color),
      );
}

class _PlayPainter extends CustomPainter {
  _PlayPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    // Lucide: <polygon points="6 3 20 12 6 21 6 3"/>, 2px round stroke.
    final path = Path()
      ..moveTo(6 * s, 3 * s)
      ..lineTo(20 * s, 12 * s)
      ..lineTo(6 * s, 21 * s)
      ..close();
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2 * s
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas
      ..drawPath(path, paint..style = PaintingStyle.fill)
      ..drawPath(path, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_PlayPainter old) => old.color != color;
}

class _PausePainter extends CustomPainter {
  _PausePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()..color = color;
    // Lucide: rects x=6 and x=14, y=4, 4×16, rx=1 (plus 2px stroke → 6×18).
    for (final x in [5.0, 13.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * s, 3 * s, 6 * s, 18 * s),
          Radius.circular(2 * s),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PausePainter old) => old.color != color;
}
