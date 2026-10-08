import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/audio/audio_engine.dart';
import '../../core/motion/motion.dart';
import '../../core/storage/app_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/status_layout.dart';
import '../recordings/take.dart';
import '../recordings/voice_style.dart';
import '../result/result_screen.dart';
import 'conversion_failed_screen.dart';

/// Figma "05 · Conversion — Processing" (9:2).
///
/// No fake percentage (spec §19): an animated indicator instead. The
/// original is never touched. Cancel returns to voice selection.
class ConvertingScreen extends ConsumerStatefulWidget {
  const ConvertingScreen({super.key, required this.take, required this.voice});

  final Take take;
  final VoiceStyle voice;

  @override
  ConsumerState<ConvertingScreen> createState() => _ConvertingScreenState();
}

class _ConvertingScreenState extends ConsumerState<ConvertingScreen> {
  /// Keeps the screen up long enough to read, even for very short clips.
  static const _minShown = Duration(milliseconds: 1400);
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final out = ref.read(appStorageProvider).workPath(
          'result_${widget.take.id}_${widget.voice.name}_'
          '${DateTime.now().millisecondsSinceEpoch}.wav',
        );
    final started = DateTime.now();
    try {
      await AudioEngine.convert(
        inputPath: widget.take.path,
        outputPath: out,
        voice: widget.voice,
      );
      final analysis = await AudioEngine.analyze(out);
      final wait = _minShown - DateTime.now().difference(started);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      if (_cancelled) {
        await AudioEngine.deleteQuietly(out);
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            take: widget.take,
            voice: widget.voice,
            convertedPath: out,
            convertedWaveform: analysis.waveform,
            convertedDuration: analysis.duration,
          ),
        ),
      );
    } catch (e) {
      await AudioEngine.deleteQuietly(out);
      if (_cancelled || !mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ConversionFailedScreen(
            take: widget.take,
            voice: widget.voice,
            outOfSpace: isOutOfSpace(e),
          ),
        ),
      );
    }
  }

  void _cancel() {
    _cancelled = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _cancelled = true;
      },
      child: Scaffold(
        appBar: const AppTopBar(title: 'Converting', nav: TopBarNav.none),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProcessingVisual(icon: widget.voice.icon),
                const SizedBox(height: 12 + 12 + 12),
                StatusChip(label: '${widget.voice.label} voice', tonal: true),
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'Creating your new voice…',
                    textAlign: TextAlign.center,
                    style: AppText.headline.copyWith(color: c.textPrimary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This may take a few seconds.',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: 12 + 8 + 12),
                const _IndeterminateBar(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: ActionsFooter(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.shieldCheck, size: 16, color: c.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Your original recording is kept',
                  style: AppText.label.copyWith(color: c.textSecondary),
                ),
              ],
            ),
            AppTextButton(
              label: 'Cancel',
              tone: TextButtonTone.neutral,
              expand: true,
              onPressed: _cancel,
            ),
          ],
        ),
      ),
    );
  }
}

/// 184dp layered circles with a rotating arc around the voice icon.
/// Static when the user prefers reduced motion.
class _ProcessingVisual extends StatefulWidget {
  const _ProcessingVisual({required this.icon});

  final IconData icon;

  @override
  State<_ProcessingVisual> createState() => _ProcessingVisualState();
}

class _ProcessingVisualState extends State<_ProcessingVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        width: 184,
        height: 184,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final pulse = 0.5 + 0.5 * math.sin(_c.value * 2 * math.pi);
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 0.96 + 0.04 * pulse,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.primaryContainer,
                    ),
                  ),
                ),
                Container(
                  width: 144,
                  height: 144,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.primary.withValues(alpha: 0.22),
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.primaryContainer,
                  ),
                ),
                Transform.rotate(
                  angle: _c.value * 2 * math.pi,
                  child: CustomPaint(
                    size: const Size(120, 120),
                    painter: _ArcPainter(c.primary),
                  ),
                ),
                Icon(widget.icon, size: 32, color: c.onPrimaryContainer),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
      Offset.zero & size,
      -math.pi / 2,
      math.pi * 0.95,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter o) => o.color != color;
}

/// 200×4 track with a 72dp segment sliding back and forth (no fake %).
class _IndeterminateBar extends StatefulWidget {
  const _IndeterminateBar();

  @override
  State<_IndeterminateBar> createState() => _IndeterminateBarState();
}

class _IndeterminateBarState extends State<_IndeterminateBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
      _c.value = 0.4;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Working',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Container(
          width: 200,
          height: 4,
          color: c.textSecondary,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => Stack(
              children: [
                Positioned(
                  left: (200 - 72) * Curves.easeInOut.transform(_c.value),
                  top: 0,
                  bottom: 0,
                  width: 72,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
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
