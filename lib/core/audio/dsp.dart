import 'dart:math' as math;
import 'dart:typed_data';

/// Small, dependency-free DSP building blocks used by the voice effects.
/// Everything works on mono Float32 samples in -1..1.
abstract final class Dsp {
  /// Reads [x] at a fractional index with linear interpolation (0 outside).
  static double _at(Float32List x, double i) {
    if (i < 0) return 0;
    final i0 = i.floor();
    if (i0 >= x.length - 1) return i0 < x.length ? x[i0] : 0;
    final f = i - i0;
    return x[i0] * (1 - f) + x[i0 + 1] * f;
  }

  /// Changes pitch by [ratio] (2.0 = one octave up) without changing length.
  /// Two crossfaded delay taps (classic delay-line pitch shifter).
  static Float32List pitchShift(Float32List x, int sr, double ratio,
      {double windowMs = 50}) {
    if ((ratio - 1).abs() < 1e-3) return Float32List.fromList(x);
    final window = sr * windowMs / 1000;
    final step = (1 - ratio) / window;
    final out = Float32List(x.length);
    var phase = 0.0;
    for (var n = 0; n < x.length; n++) {
      final p2 = (phase + 0.5) % 1.0;
      final g1 = math.pow(math.sin(math.pi * phase), 2).toDouble();
      final g2 = 1 - g1;
      out[n] = g1 * _at(x, n - phase * window) + g2 * _at(x, n - p2 * window);
      phase += step;
      if (phase >= 1) phase -= 1;
      if (phase < 0) phase += 1;
    }
    return out;
  }

  /// Multiplies by a sine carrier (metallic / robotic timbre).
  static Float32List ringMod(Float32List x, int sr, double hz, double mix) {
    final out = Float32List(x.length);
    final w = 2 * math.pi * hz / sr;
    for (var n = 0; n < x.length; n++) {
      final wet = x[n] * math.sin(w * n);
      out[n] = x[n] * (1 - mix) + wet * mix;
    }
    return out;
  }

  /// Feedback comb / echo. [tailSeconds] extends the output so echoes fade.
  static Float32List echo(Float32List x, int sr,
      {required double delaySeconds,
      required double feedback,
      required double mix,
      double tailSeconds = 0}) {
    final d = (delaySeconds * sr).round().clamp(1, 10 * sr);
    final len = x.length + (tailSeconds * sr).round();
    // buf = dry + all echoes; output keeps dry at full level and adds
    // the echoes (buf - dry) scaled by [mix].
    final buf = Float32List(len);
    final out = Float32List(len);
    for (var n = 0; n < len; n++) {
      final dry = n < x.length ? x[n] : 0.0;
      final delayed = n >= d ? buf[n - d] : 0.0;
      buf[n] = dry + delayed * feedback;
      out[n] = dry + (buf[n] - dry) * mix;
    }
    return out;
  }

  /// Periodically modulated short delay (wobble / chorus-like vibrato).
  static Float32List vibrato(Float32List x, int sr,
      {required double rateHz, required double depthMs}) {
    final out = Float32List(x.length);
    final depth = depthMs * sr / 1000;
    final w = 2 * math.pi * rateHz / sr;
    for (var n = 0; n < x.length; n++) {
      final d = depth * (1 + math.sin(w * n)) / 2 + 1;
      out[n] = _at(x, n - d);
    }
    return out;
  }

  /// Soft saturation. [drive] > 1 adds grit.
  static Float32List softClip(Float32List x, double drive) {
    final out = Float32List(x.length);
    final norm = _tanh(drive);
    for (var n = 0; n < x.length; n++) {
      out[n] = _tanh(x[n] * drive) / norm;
    }
    return out;
  }

  static double _tanh(double v) {
    final e = math.exp(2 * v.clamp(-20.0, 20.0));
    return (e - 1) / (e + 1);
  }

  static Float32List lowPass(Float32List x, int sr, double hz, {double q = 0.707}) =>
      _Biquad.lowPass(sr, hz, q).run(x);

  static Float32List highPass(Float32List x, int sr, double hz, {double q = 0.707}) =>
      _Biquad.highPass(sr, hz, q).run(x);

  static Float32List peak(Float32List x, int sr, double hz, double gainDb,
          {double q = 1}) =>
      _Biquad.peaking(sr, hz, q, gainDb).run(x);

  /// Adds a tiny bit of hiss (radio character).
  static Float32List noise(Float32List x, double amount, {int seed = 7}) {
    final r = math.Random(seed);
    final out = Float32List(x.length);
    for (var n = 0; n < x.length; n++) {
      out[n] = x[n] + (r.nextDouble() * 2 - 1) * amount;
    }
    return out;
  }

  /// Small Freeverb-style room/hall. [size] 0..1 (bigger = longer tail),
  /// [damp] 0..1 (higher = darker tail), [mix] = wet level.
  static Float32List reverb(Float32List x, int sr,
      {double size = 0.6,
      double damp = 0.4,
      double mix = 0.3,
      double tailSeconds = 1.0}) {
    final scale = sr / 44100;
    const combTune = [1116, 1188, 1277, 1356, 1422, 1491];
    const apTune = [556, 441, 341];
    final len = x.length + (tailSeconds * sr).round();
    final feedback = 0.7 + 0.28 * size.clamp(0.0, 1.0);
    final wet = Float64List(len);

    for (final t in combTune) {
      final d = math.max(1, (t * scale).round());
      final buf = Float64List(d);
      var idx = 0;
      var store = 0.0;
      for (var n = 0; n < len; n++) {
        final input = n < x.length ? x[n] * 0.015 : 0.0;
        final o = buf[idx];
        store = o * (1 - damp) + store * damp;
        buf[idx] = input + store * feedback;
        idx = idx + 1 == d ? 0 : idx + 1;
        wet[n] += o;
      }
    }
    for (final t in apTune) {
      final d = math.max(1, (t * scale).round());
      final buf = Float64List(d);
      var idx = 0;
      for (var n = 0; n < len; n++) {
        final b = buf[idx];
        final o = -wet[n] + b;
        buf[idx] = wet[n] + b * 0.5;
        idx = idx + 1 == d ? 0 : idx + 1;
        wet[n] = o;
      }
    }
    final out = Float32List(len);
    for (var n = 0; n < len; n++) {
      final dry = n < x.length ? x[n] : 0.0;
      out[n] = dry + wet[n] * mix * 3;
    }
    return out;
  }

  /// Amplitude wobble at [rateHz]; [depth] 0..1.
  static Float32List tremolo(Float32List x, int sr,
      {required double rateHz, required double depth}) {
    final out = Float32List(x.length);
    final w = 2 * math.pi * rateHz / sr;
    for (var n = 0; n < x.length; n++) {
      out[n] = x[n] * (1 - depth * (0.5 + 0.5 * math.sin(w * n)));
    }
    return out;
  }

  /// Adds short rising "blip" bubbles across the clip.
  static Float32List bubbles(Float32List x, int sr,
      {double level = 0.06, int seed = 3}) {
    final r = math.Random(seed);
    final out = Float32List.fromList(x);
    var n = (r.nextDouble() * 0.2 * sr).round();
    while (n < x.length) {
      final dur = ((0.025 + r.nextDouble() * 0.04) * sr).round();
      final f0 = 250 + r.nextDouble() * 350;
      final amp = level * (0.5 + r.nextDouble());
      var ph = 0.0;
      for (var i = 0; i < dur && n + i < out.length; i++) {
        final t = i / dur;
        ph += 2 * math.pi * f0 * (1 + 1.5 * t) / sr;
        out[n + i] += amp * math.sin(ph) * math.sin(math.pi * t);
      }
      n += ((0.08 + r.nextDouble() * 0.35) * sr).round();
    }
    return out;
  }

  /// Returns `a + b * gain`, as long as the longer of the two.
  static Float32List mix(Float32List a, Float32List b, double gain) {
    final out = Float32List(math.max(a.length, b.length));
    for (var n = 0; n < out.length; n++) {
      out[n] = (n < a.length ? a[n] : 0.0) + (n < b.length ? b[n] * gain : 0.0);
    }
    return out;
  }

  /// Scales so the loudest sample hits [target].
  static Float32List normalize(Float32List x, {double target = 0.95}) {
    var peak = 0.0;
    for (final v in x) {
      final a = v.abs();
      if (a > peak) peak = a;
    }
    if (peak < 1e-6) return x;
    final g = target / peak;
    final out = Float32List(x.length);
    for (var n = 0; n < x.length; n++) {
      out[n] = x[n] * g;
    }
    return out;
  }
}

/// RBJ cookbook biquad filter.
class _Biquad {
  _Biquad(this.b0, this.b1, this.b2, this.a1, this.a2);

  final double b0, b1, b2, a1, a2;

  factory _Biquad._norm(double b0, double b1, double b2, double a0, double a1,
          double a2) =>
      _Biquad(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0);

  factory _Biquad.lowPass(int sr, double f, double q) {
    final w = 2 * math.pi * f / sr, c = math.cos(w), al = math.sin(w) / (2 * q);
    return _Biquad._norm((1 - c) / 2, 1 - c, (1 - c) / 2, 1 + al, -2 * c, 1 - al);
  }

  factory _Biquad.highPass(int sr, double f, double q) {
    final w = 2 * math.pi * f / sr, c = math.cos(w), al = math.sin(w) / (2 * q);
    return _Biquad._norm((1 + c) / 2, -(1 + c), (1 + c) / 2, 1 + al, -2 * c, 1 - al);
  }

  factory _Biquad.peaking(int sr, double f, double q, double db) {
    final a = math.pow(10, db / 40).toDouble();
    final w = 2 * math.pi * f / sr, c = math.cos(w), al = math.sin(w) / (2 * q);
    return _Biquad._norm(
        1 + al * a, -2 * c, 1 - al * a, 1 + al / a, -2 * c, 1 - al / a);
  }

  Float32List run(Float32List x) {
    final y = Float32List(x.length);
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0;
    for (var n = 0; n < x.length; n++) {
      final x0 = x[n];
      final y0 = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
      y[n] = y0;
      x2 = x1;
      x1 = x0;
      y2 = y1;
      y1 = y0;
    }
    return y;
  }
}
