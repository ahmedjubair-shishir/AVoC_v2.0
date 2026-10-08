import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// What is currently playing, app-wide. Only one sound plays at a time
/// (spec §17, §37): starting another file stops the previous one.
class PlaybackState {
  const PlaybackState({
    this.path,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final String? path;
  final bool playing;
  final Duration position;
  final Duration duration;

  bool isPlaying(String p) => playing && path == p;

  double progressOf(String p) {
    if (path != p || duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  PlaybackState copyWith({
    String? path,
    bool? playing,
    Duration? position,
    Duration? duration,
  }) =>
      PlaybackState(
        path: path ?? this.path,
        playing: playing ?? this.playing,
        position: position ?? this.position,
        duration: duration ?? this.duration,
      );
}

final _audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final p = AudioPlayer();
  ref.onDispose(p.dispose);
  return p;
});

class PlaybackController extends Notifier<PlaybackState> {
  AudioPlayer get _p => ref.read(_audioPlayerProvider);

  @override
  PlaybackState build() {
    final p = ref.watch(_audioPlayerProvider);
    final subs = <StreamSubscription<Object?>>[
      p.positionStream.listen((pos) {
        if (state.path != null) state = state.copyWith(position: pos);
      }),
      p.durationStream.listen((d) {
        if (d != null) state = state.copyWith(duration: d);
      }),
      p.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed) {
          // Finished: rewind so the next tap plays from the start.
          state = state.copyWith(playing: false, position: Duration.zero);
          p.pause();
          p.seek(Duration.zero);
        } else {
          state = state.copyWith(playing: s.playing);
        }
      }),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        s.cancel();
      }
    });
    return const PlaybackState();
  }

  /// Plays [path], or pauses it if it is already playing.
  Future<void> toggle(String path) async {
    if (state.path == path) {
      if (_p.playing) {
        await _p.pause();
      } else {
        unawaited(_p.play());
      }
      return;
    }
    await _p.stop();
    state = PlaybackState(path: path);
    final d = await _p.setFilePath(path);
    state = state.copyWith(duration: d ?? Duration.zero);
    unawaited(_p.play());
  }

  Future<void> seek(String path, Duration to) async {
    if (state.path != path) {
      await _p.stop();
      state = PlaybackState(path: path);
      final d = await _p.setFilePath(path);
      state = state.copyWith(duration: d ?? Duration.zero);
    }
    await _p.seek(to);
    state = state.copyWith(position: to);
  }

  /// Stops whatever is playing (e.g. when leaving a screen).
  Future<void> stop() async {
    await _p.stop();
    state = const PlaybackState();
  }
}

final playbackProvider =
    NotifierProvider<PlaybackController, PlaybackState>(PlaybackController.new);
