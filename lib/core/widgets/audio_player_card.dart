import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/recordings/format.dart';
import '../../features/recordings/voice_style.dart';
import '../audio/playback.dart';
import '../motion/motion.dart';
import '../motion/pressable.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'chips.dart';
import 'lucide_glyphs.dart';
import 'seek_bar.dart';
import 'waveform_bars.dart';

/// Figma "Audio player": Original = neutral card; Converted = tonal card with
/// a 2px primary border. Play/Pause, seek, position and duration.
/// Only one player plays at a time (shared [playbackProvider]).
class AudioPlayerCard extends ConsumerWidget {
  const AudioPlayerCard({
    super.key,
    required this.path,
    required this.title,
    required this.duration,
    required this.waveform,
    this.voice,
    this.showDurationInHeader = false,
  });

  final String path;
  final String title;
  final Duration duration;
  final List<double> waveform;

  /// Null = original recording; otherwise the converted voice.
  final VoiceStyle? voice;
  final bool showDurationInHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final pb = ref.watch(playbackProvider);
    final converted = voice != null;
    final playing = pb.isPlaying(path);
    final isCurrent = pb.path == path;
    final total = isCurrent && pb.duration > Duration.zero ? pb.duration : duration;
    final position = isCurrent ? pb.position : Duration.zero;
    final progress = isCurrent ? pb.progressOf(path) : 0.0;
    final d = context.reduceMotion ? Duration.zero : AppMotion.medium;

    final fg = converted ? c.onPrimaryContainer : c.textSecondary;

    return AnimatedContainer(
      duration: d,
      curve: AppMotion.enter,
      padding: EdgeInsets.fromLTRB(
        converted ? 15 : 16, converted ? 15 : 16,
        converted ? 15 : 16, converted ? 11 : 12,
      ),
      decoration: BoxDecoration(
        color: converted ? c.primaryContainer : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: converted ? c.primary : c.border,
          width: converted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          SizedBox(
            height: 28,
            child: Row(
              children: [
                Icon(converted ? voice!.icon : LucideIcons.mic, size: 18, color: fg),
                const SizedBox(width: AppSpace.s8),
                Expanded(
                  child: Text(
                    converted ? voice!.label : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label.copyWith(color: fg),
                  ),
                ),
                if (showDurationInHeader)
                  Text(formatDuration(duration),
                      style: AppText.label.copyWith(color: fg)),
                if (converted)
                  AnimatedSwitcher(
                    duration: d,
                    child: playing
                        ? const StatusChip(key: ValueKey('on'), label: 'Playing')
                        : const SizedBox(key: ValueKey('off')),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          WaveformBars(
            values: waveform,
            color: converted ? c.primary : c.textSecondary,
          ),
          const SizedBox(height: AppSpace.s12),
          Row(
            children: [
              _PlayButton(
                playing: playing,
                label: '${playing ? 'Pause' : 'Play'} '
                    '${converted ? 'converted' : 'original'} recording',
                onTap: () => ref.read(playbackProvider.notifier).toggle(path),
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SeekBar(
                      value: progress,
                      trackColor: converted ? c.onPrimaryContainer : c.textSecondary,
                      activeColor: c.primary,
                      thumbColor: c.primary,
                      onSeek: (v) => ref.read(playbackProvider.notifier).seek(
                            path,
                            Duration(
                              milliseconds: (total.inMilliseconds * v).round(),
                            ),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatDuration(position),
                            style: AppText.caption.copyWith(color: fg)),
                        Text(formatDuration(total),
                            style: AppText.caption.copyWith(color: fg)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 48dp round play/pause. Tonal when idle, filled primary while playing.
class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playing,
    required this.label,
    required this.onTap,
  });

  final bool playing;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PlayPauseButton(playing: playing, label: label, onTap: onTap);
  }
}

/// Shared round play/pause button (players, recording rows).
class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    super.key,
    required this.playing,
    required this.label,
    required this.onTap,
    this.size = 48,
    this.iconSize = 20,
  });

  final bool playing;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = context.reduceMotion ? Duration.zero : AppMotion.fast;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        scale: 0.88,
        child: Material(
          color: playing ? c.primary : c.primaryContainer,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: AnimatedSwitcher(
                  duration: d,
                  transitionBuilder: (child, a) =>
                      ScaleTransition(scale: a, child: child),
                  child: playing
                      ? PauseGlyph(
                          key: const ValueKey('pause'),
                          size: iconSize,
                          color: c.onPrimary,
                        )
                      : PlayGlyph(
                          key: const ValueKey('play'),
                          size: iconSize,
                          color: c.onPrimaryContainer,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
