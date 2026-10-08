import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/audio/audio_engine.dart';
import '../../core/audio/playback.dart';
import '../../core/audio/recorder.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/storage/app_storage.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/lucide_glyphs.dart';
import '../../core/widgets/overlays.dart';
import '../recordings/format.dart';
import '../recordings/take.dart';
import 'preview_screen.dart';

enum _Phase { ready, recording, paused, finishing }

/// Figma "02 · Recording" — Ready, Recording, Paused (6:58, 6:119, 6:181).
///
/// * Never starts automatically: the user taps the record button (spec §8).
/// * 3-minute limit with "m:ss remaining"; auto-stops at 3:00 (spec §10, §39).
/// * Close/back while recording asks "Discard this recording?" (spec §39).
/// * Pauses itself if the app goes to the background.
class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  static const maxLength = Duration(minutes: 3);

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen>
    with WidgetsBindingObserver {
  static const _bars = 29;

  final _recorder = Recorder();
  final _clock = Stopwatch();
  Duration _banked = Duration.zero;
  Timer? _ticker;
  StreamSubscription<double>? _levelSub;
  final List<double> _levels = List<double>.filled(_bars, 0, growable: true);
  _Phase _phase = _Phase.ready;
  String? _path;

  Duration get _elapsed => _banked + _clock.elapsed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Nothing else should be playing while recording.
    final playback = ref.read(playbackProvider.notifier);
    Future.microtask(playback.stop);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _levelSub?.cancel();
    if (_phase == _Phase.recording || _phase == _Phase.paused) {
      _recorder.cancel();
    }
    _recorder.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _phase == _Phase.recording) {
      _pause();
    }
  }

  Future<void> _start() async {
    final storage = ref.read(appStorageProvider);
    final path = storage.workPath('take_${DateTime.now().millisecondsSinceEpoch}.wav');
    try {
      await _recorder.start(path);
    } catch (e) {
      if (mounted) showErrorSnack(context, 'Couldn’t start recording.');
      return;
    }
    HapticFeedback.mediumImpact();
    _path = path;
    _banked = Duration.zero;
    _clock
      ..reset()
      ..start();
    _levelSub = _recorder.levels().listen((v) {
      if (_phase != _Phase.recording) return;
      setState(() {
        _levels
          ..removeAt(0)
          ..add(v);
      });
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_elapsed >= RecordScreen.maxLength) {
        _finish(hitMax: true);
      } else if (mounted) {
        setState(() {});
      }
    });
    setState(() => _phase = _Phase.recording);
  }

  Future<void> _pause() async {
    if (_phase != _Phase.recording) return;
    await _recorder.pause();
    _banked += _clock.elapsed;
    _clock
      ..stop()
      ..reset();
    HapticFeedback.selectionClick();
    if (mounted) setState(() => _phase = _Phase.paused);
  }

  Future<void> _resume() async {
    if (_phase != _Phase.paused) return;
    await _recorder.resume();
    _clock.start();
    HapticFeedback.selectionClick();
    setState(() => _phase = _Phase.recording);
  }

  Future<void> _finish({bool hitMax = false}) async {
    if (_phase != _Phase.recording && _phase != _Phase.paused) return;
    final recorded = hitMax ? RecordScreen.maxLength : _elapsed;
    setState(() => _phase = _Phase.finishing);
    _ticker?.cancel();
    _clock.stop();
    HapticFeedback.mediumImpact();

    final path = await _recorder.stop() ?? _path;
    if (path == null || !mounted) return;

    AudioAnalysis? analysis;
    try {
      analysis = await AudioEngine.analyze(path);
    } catch (_) {}
    if (!mounted) return;

    final take = Take(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: path,
      name: nextTakeName(ref.read(sharedPreferencesProvider)),
      duration: analysis?.duration ?? recorded,
      waveform: analysis?.waveform ?? const [],
    );
    final issue = take.duration < const Duration(seconds: 3)
        ? TakeIssue.tooShort
        : (analysis != null && !analysis.hasVoice)
            ? TakeIssue.noAudio
            : null;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PreviewScreen(take: take, issue: issue, hitMax: hitMax),
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final discard = await showAppDialog<bool>(
      context,
      title: 'Discard this recording?',
      body: 'You’ll lose what you’ve recorded so far.',
      actions: const [
        DialogAction('Keep Recording', false),
        DialogAction('Discard', true, tone: TextButtonTone.destructive),
      ],
    );
    if (discard == true && mounted) {
      await _recorder.cancel();
      _phase = _Phase.ready;
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = _phase == _Phase.recording || _phase == _Phase.paused;
    final remaining = RecordScreen.maxLength - _elapsed;

    return PopScope(
      canPop: !active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && active) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: 'New recording',
          nav: TopBarNav.close,
          onNav: () => active ? _confirmLeave() : Navigator.of(context).pop(),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: AppMotion.medium,
                child: _statusChip(c),
              ),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                label: 'Recorded ${formatDuration(_elapsed)}',
                excludeSemantics: true,
                child: Text(
                  formatDuration(_phase == _Phase.ready ? Duration.zero : _elapsed),
                  style: AppText.timer.copyWith(color: c.textPrimary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _phase == _Phase.ready
                    ? 'Up to 3 minutes'
                    : '${formatShort(remaining.isNegative ? Duration.zero : remaining)} remaining',
                style: AppText.body.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 12 + 24 + 12),
              _LevelMeter(
                levels: _levels,
                color: _phase == _Phase.recording ? c.primary : c.textSecondary,
                idle: _phase == _Phase.ready,
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 48),
            child: AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: AppMotion.enter,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(
                  scale: Tween(begin: 0.9, end: 1.0).animate(a),
                  child: child,
                ),
              ),
              child: _controls(c),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(AppColors c) {
    switch (_phase) {
      case _Phase.ready:
        return StatusChip(
          key: const ValueKey('ready'),
          label: 'Ready to record',
          leading: Icon(LucideIcons.mic, size: 16, color: c.textPrimary),
        );
      case _Phase.paused:
        return StatusChip(
          key: const ValueKey('paused'),
          label: 'Recording paused',
          leading: PauseGlyph(size: 16, color: c.textPrimary),
        );
      case _Phase.recording:
      case _Phase.finishing:
        return Container(
          key: const ValueKey('rec'),
          padding: const EdgeInsets.fromLTRB(12, 6, 14, 6),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LiveDot(color: c.error),
              const SizedBox(width: 8),
              Text('Recording',
                  style: AppText.label.copyWith(color: c.textPrimary)),
            ],
          ),
        );
    }
  }

  Widget _controls(AppColors c) {
    switch (_phase) {
      case _Phase.ready:
        return _RecordControl(
          key: const ValueKey('start'),
          size: 80,
          filled: true,
          icon: Icon(LucideIcons.mic, size: 32, color: c.onPrimary),
          label: 'Tap to start',
          semantic: 'Record voice',
          onTap: _start,
        );
      case _Phase.recording:
      case _Phase.paused:
      case _Phase.finishing:
        final paused = _phase == _Phase.paused;
        return Row(
          key: const ValueKey('active'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RecordControl(
              size: 64,
              filled: false,
              icon: paused
                  ? Icon(LucideIcons.mic, size: 24, color: c.onPrimaryContainer)
                  : PauseGlyph(size: 24, color: c.onPrimaryContainer),
              label: paused ? 'Resume' : 'Pause',
              semantic: paused ? 'Resume recording' : 'Pause recording',
              onTap: _phase == _Phase.finishing
                  ? null
                  : (paused ? _resume : _pause),
            ),
            const SizedBox(width: 48),
            _RecordControl(
              size: 64,
              filled: true,
              icon: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: c.onPrimary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              label: 'Stop',
              semantic: 'Stop recording',
              onTap: _phase == _Phase.finishing ? null : () => _finish(),
            ),
          ],
        );
    }
  }
}

/// Figma "Record control": big round button with a visible label.
class _RecordControl extends StatelessWidget {
  const _RecordControl({
    super.key,
    required this.size,
    required this.filled,
    required this.icon,
    required this.label,
    required this.semantic,
    required this.onTap,
  });

  final double size;
  final bool filled;
  final Widget icon;
  final String label;
  final String semantic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: semantic,
      excludeSemantics: true,
      child: Pressable(
        scale: 0.9,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: filled ? c.primary : c.primaryContainer,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Center(child: icon),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(label, style: AppText.label.copyWith(color: c.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live audio level (Figma "Audio level": 29 bars, 5dp, 72dp tall).
/// New levels enter on the right and scroll left.
class _LevelMeter extends StatelessWidget {
  const _LevelMeter({
    required this.levels,
    required this.color,
    required this.idle,
  });

  final List<double> levels;
  final Color color;
  final bool idle;

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return ExcludeSemantics(
      child: SizedBox(
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < levels.length; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              AnimatedContainer(
                duration: reduce ? Duration.zero : const Duration(milliseconds: 90),
                width: 5,
                height: idle ? 6 : 6 + 66 * levels[i],
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pulsing red dot shown while recording.
class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.color});

  final Color color;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.value = 1;
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
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
