import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Figma player "Slider": 20dp tall, 4dp track, 16dp thumb, edge to edge.
/// Seeking is done here (the waveform is decorative, spec §38).
class SeekBar extends StatefulWidget {
  const SeekBar({
    super.key,
    required this.value,
    required this.onSeek,
    required this.trackColor,
    required this.activeColor,
    required this.thumbColor,
    this.semanticLabel = 'Playback position',
  });

  /// 0..1
  final double value;
  final ValueChanged<double> onSeek;
  final Color trackColor;
  final Color activeColor;
  final Color thumbColor;
  final String semanticLabel;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _drag;

  double _fromDx(double dx, double width) =>
      width <= 16 ? 0 : ((dx - 8) / (width - 16)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final v = (_drag ?? widget.value).clamp(0.0, 1.0);
    return Semantics(
      slider: true,
      label: widget.semanticLabel,
      value: '${(v * 100).round()}%',
      increasedValue: '${((v + 0.1).clamp(0, 1) * 100).round()}%',
      decreasedValue: '${((v - 0.1).clamp(0, 1) * 100).round()}%',
      onIncrease: () => widget.onSeek((v + 0.1).clamp(0.0, 1.0)),
      onDecrease: () => widget.onSeek((v - 0.1).clamp(0.0, 1.0)),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => widget.onSeek(_fromDx(d.localPosition.dx, w)),
            onHorizontalDragStart: (d) {
              HapticFeedback.selectionClick();
              setState(() => _drag = _fromDx(d.localPosition.dx, w));
            },
            onHorizontalDragUpdate: (d) =>
                setState(() => _drag = _fromDx(d.localPosition.dx, w)),
            onHorizontalDragEnd: (_) {
              final target = _drag;
              setState(() => _drag = null);
              if (target != null) widget.onSeek(target);
            },
            child: SizedBox(
              height: 20,
              width: w,
              child: CustomPaint(
                painter: _SeekPainter(
                  value: v,
                  track: widget.trackColor,
                  active: widget.activeColor,
                  thumb: widget.thumbColor,
                  dragging: _drag != null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SeekPainter extends CustomPainter {
  _SeekPainter({
    required this.value,
    required this.track,
    required this.active,
    required this.thumb,
    required this.dragging,
  });

  final double value;
  final Color track, active, thumb;
  final bool dragging;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final r = const Radius.circular(2);
    canvas.drawRRect(
      RRect.fromLTRBR(0, cy - 2, size.width, cy + 2, r),
      Paint()..color = track,
    );
    final x = 8 + (size.width - 16) * value;
    canvas.drawRRect(
      RRect.fromLTRBR(0, cy - 2, x, cy + 2, r),
      Paint()..color = active,
    );
    canvas.drawCircle(Offset(x, cy), dragging ? 9 : 8, Paint()..color = thumb);
  }

  @override
  bool shouldRepaint(_SeekPainter o) =>
      o.value != value ||
      o.track != track ||
      o.active != active ||
      o.thumb != thumb ||
      o.dragging != dragging;
}
