import 'dart:async';

import 'package:record/record.dart';

/// Thin wrapper around the `record` plugin: 44.1 kHz mono 16-bit WAV.
class Recorder {
  final AudioRecorder _rec = AudioRecorder();

  Future<void> start(String path) => _rec.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );

  Future<void> pause() => _rec.pause();
  Future<void> resume() => _rec.resume();

  /// Returns the file path of the finished recording.
  Future<String?> stop() => _rec.stop();

  /// Stops and deletes the file.
  Future<void> cancel() => _rec.cancel();

  /// Microphone level 0..1, about 12 times per second.
  Stream<double> levels() => _rec
      .onAmplitudeChanged(const Duration(milliseconds: 80))
      .map((a) => ((a.current + 50) / 50).clamp(0.0, 1.0));

  Future<void> dispose() => _rec.dispose();
}
