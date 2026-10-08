import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../features/recordings/voice_style.dart';
import 'voice_effects.dart';
import 'wav.dart';

/// Facts about a finished recording, used for edge cases (spec §13, §39).
class AudioAnalysis {
  const AudioAnalysis({
    required this.duration,
    required this.hasVoice,
    required this.waveform,
  });

  final Duration duration;

  /// False when we "couldn't detect enough audio".
  final bool hasVoice;

  /// 30 bar heights (0..1) for the decorative waveform.
  final List<double> waveform;
}

/// Heavy audio work, always run off the UI thread (in an isolate).
abstract final class AudioEngine {
  static const waveformBars = 30;

  /// Applies [voice] to [inputPath] and writes a WAV to [outputPath].
  /// [maxSeconds] limits the length (used for short voice previews).
  static Future<void> convert({
    required String inputPath,
    required String outputPath,
    required VoiceStyle voice,
    double? maxSeconds,
  }) {
    return Isolate.run(() {
      final audio = Wav.readFileSync(inputPath);
      var samples = audio.samples;
      if (maxSeconds != null) {
        final max = (maxSeconds * audio.sampleRate).round();
        if (samples.length > max) samples = Float32List.sublistView(samples, 0, max);
      }
      final out = VoiceEffects.apply(voice, samples, audio.sampleRate);
      Wav.writeFileSync(outputPath, PcmAudio(out, audio.sampleRate));
    });
  }

  static Future<AudioAnalysis> analyze(String path) {
    return Isolate.run(() {
      final audio = Wav.readFileSync(path);
      return AudioAnalysis(
        duration: audio.duration,
        hasVoice: _hasVoice(audio),
        waveform: _waveform(audio.samples),
      );
    });
  }

  static Future<List<double>> waveform(String path) {
    return Isolate.run(() => _waveform(Wav.readFileSync(path).samples));
  }

  /// Voice is "detected" if at least ~0.5s worth of 50ms frames are clearly
  /// above the microphone noise floor.
  static bool _hasVoice(PcmAudio a) {
    final frame = (a.sampleRate * 0.05).round();
    if (frame <= 0) return false;
    var loudFrames = 0;
    for (var start = 0; start + frame <= a.samples.length; start += frame) {
      var sum = 0.0;
      for (var i = start; i < start + frame; i++) {
        sum += a.samples[i] * a.samples[i];
      }
      if (math.sqrt(sum / frame) > 0.02) loudFrames++;
    }
    return loudFrames >= 10;
  }

  static List<double> _waveform(Float32List s) {
    final out = List<double>.filled(waveformBars, 0);
    if (s.isEmpty) return out;
    final per = (s.length / waveformBars).ceil();
    var max = 0.0;
    for (var b = 0; b < waveformBars; b++) {
      final start = b * per;
      final end = math.min(start + per, s.length);
      var sum = 0.0;
      for (var i = start; i < end; i++) {
        sum += s[i] * s[i];
      }
      final rms = end > start ? math.sqrt(sum / (end - start)) : 0.0;
      out[b] = rms;
      if (rms > max) max = rms;
    }
    if (max <= 0) return out;
    return [for (final v in out) (v / max).clamp(0.0, 1.0)];
  }

  /// Deletes a file if it exists, ignoring errors.
  static Future<void> deleteQuietly(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
