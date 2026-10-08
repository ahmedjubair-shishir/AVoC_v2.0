import 'dart:io';
import 'dart:typed_data';

/// Mono audio as floating-point samples in the range -1..1.
class PcmAudio {
  PcmAudio(this.samples, this.sampleRate);

  final Float32List samples;
  final int sampleRate;

  Duration get duration => Duration(
        microseconds: (samples.length * 1000000 / sampleRate).round(),
      );
}

/// Minimal 16-bit PCM WAV reader/writer (pure Dart, no plugins).
abstract final class Wav {
  static PcmAudio decode(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    String tag(int at) => String.fromCharCodes(bytes.sublist(at, at + 4));

    if (bytes.length < 12 || tag(0) != 'RIFF' || tag(8) != 'WAVE') {
      throw const FormatException('Not a WAV file');
    }

    var offset = 12;
    var format = 1;
    var channels = 1;
    var sampleRate = 44100;
    var bits = 16;
    int? dataStart;
    var dataLength = 0;

    while (offset + 8 <= bytes.length) {
      final id = tag(offset);
      var size = data.getUint32(offset + 4, Endian.little);
      final body = offset + 8;
      if (id == 'fmt ') {
        format = data.getUint16(body, Endian.little);
        channels = data.getUint16(body + 2, Endian.little);
        sampleRate = data.getUint32(body + 4, Endian.little);
        bits = data.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        // Some recorders leave the size as 0 / 0xFFFFFFFF while streaming.
        if (size == 0 || body + size > bytes.length) {
          size = bytes.length - body;
        }
        dataStart = body;
        dataLength = size;
        break;
      }
      offset = body + size + (size.isOdd ? 1 : 0);
    }

    if (dataStart == null) throw const FormatException('No audio data');
    if ((format != 1 && format != 0xFFFE) || bits != 16) {
      throw FormatException('Unsupported WAV format ($format, $bits-bit)');
    }

    final frames = dataLength ~/ (2 * channels);
    final out = Float32List(frames);
    for (var i = 0; i < frames; i++) {
      var sum = 0.0;
      for (var c = 0; c < channels; c++) {
        sum += data.getInt16(dataStart + (i * channels + c) * 2, Endian.little);
      }
      out[i] = sum / (32768.0 * channels);
    }
    return PcmAudio(out, sampleRate);
  }

  static Uint8List encode(PcmAudio audio) {
    final n = audio.samples.length;
    final dataBytes = n * 2;
    final bytes = Uint8List(44 + dataBytes);
    final b = ByteData.sublistView(bytes);
    void tag(int at, String s) {
      for (var i = 0; i < 4; i++) {
        bytes[at + i] = s.codeUnitAt(i);
      }
    }

    tag(0, 'RIFF');
    b.setUint32(4, 36 + dataBytes, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    b.setUint32(16, 16, Endian.little); // fmt chunk size
    b.setUint16(20, 1, Endian.little); // PCM
    b.setUint16(22, 1, Endian.little); // mono
    b.setUint32(24, audio.sampleRate, Endian.little);
    b.setUint32(28, audio.sampleRate * 2, Endian.little); // byte rate
    b.setUint16(32, 2, Endian.little); // block align
    b.setUint16(34, 16, Endian.little); // bits
    tag(36, 'data');
    b.setUint32(40, dataBytes, Endian.little);

    for (var i = 0; i < n; i++) {
      final v = (audio.samples[i] * 32767).round().clamp(-32768, 32767);
      b.setInt16(44 + i * 2, v, Endian.little);
    }
    return bytes;
  }

  static PcmAudio readFileSync(String path) =>
      decode(File(path).readAsBytesSync());

  static void writeFileSync(String path, PcmAudio audio) =>
      File(path).writeAsBytesSync(encode(audio), flush: true);
}
