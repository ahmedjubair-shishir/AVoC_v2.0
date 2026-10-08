import 'dart:math' as math;
import 'dart:typed_data';

/// How [VoiceShaper] rebuilds the "source" (vocal cord) part of the voice.
enum SourceMode {
  /// Keep your own source, shifted by `pitch` (natural pitch change).
  natural,

  /// Replace it with breath noise: every word becomes a whisper.
  whisper,

  /// Replace it with a perfectly steady buzz at `monotoneHz`
  /// (flat, synthetic "AI assistant" voice).
  monotone,
}

/// Spectral voice shaper (phase vocoder + cepstral envelope).
///
/// A voice = source (pitch, from the vocal cords) × envelope (formants,
/// from the size/shape of the mouth and throat). Splitting the two lets us
/// change them independently:
///
/// * `pitch` moves the source: 1.5 ≈ +7 semitones.
/// * `formant` stretches the envelope: >1 sounds like a smaller head
///   (female, child), <1 like a bigger one (male, giant).
///
/// This is what makes Male↔Female and Baby sound like *a person* rather
/// than a sped-up tape (which moves both together — that's Chipmunk).
abstract final class VoiceShaper {
  static const int _n = 2048; // ~46 ms at 44.1 kHz
  static const int _hop = _n ~/ 4;

  static Float32List process(
    Float32List x,
    int sr, {
    double pitch = 1,
    double formant = 1,
    SourceMode mode = SourceMode.natural,
    double monotoneHz = 140,
    int seed = 7,
  }) {
    if (x.isEmpty) return Float32List(0);
    const n = _n, hop = _hop, half = n ~/ 2, k = half + 1;
    final fft = _Fft(n);
    final lifter = math.max(8, (sr * 0.0012).round());

    final win = Float64List(n);
    for (var i = 0; i < n; i++) {
      win[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / n);
    }

    // Pad so the first/last samples get full overlap.
    final total = x.length + 2 * n;
    final out = Float64List(total + n);

    final re = Float64List(n), im = Float64List(n);
    final mag = Float64List(k), env = Float64List(k), envOut = Float64List(k);
    final lastPh = Float64List(k), sumPh = Float64List(k);
    final newMag = Float64List(k), newFreq = Float64List(k);
    final trueFreq = Float64List(k), binW = Float64List(k);
    for (var b = 0; b < k; b++) {
      binW[b] = 2 * math.pi * hop * b / n;
    }
    final rnd = math.Random(seed);

    // Gate for synthetic sources so silence doesn't turn into hiss/buzz.
    final gateRef = mode == SourceMode.natural ? 0.0 : _maxFrameRms(x, n, hop);

    for (var pos = 0; pos + n <= total; pos += hop) {
      // ---- analysis -------------------------------------------------------
      var energy = 0.0;
      for (var i = 0; i < n; i++) {
        final s = pos + i - n; // index into x
        final v = (s >= 0 && s < x.length) ? x[s] * win[i] : 0.0;
        re[i] = v;
        im[i] = 0;
        energy += v * v;
      }
      fft.run(re, im, inverse: false);

      final ph = Float64List(k);
      for (var b = 0; b < k; b++) {
        mag[b] = math.sqrt(re[b] * re[b] + im[b] * im[b]);
        ph[b] = math.atan2(im[b], re[b]);
      }

      // ---- envelope via cepstrum -----------------------------------------
      for (var b = 0; b < k; b++) {
        re[b] = math.log(mag[b] + 1e-9);
        im[b] = 0;
      }
      for (var b = 1; b < half; b++) {
        re[n - b] = re[b];
        im[n - b] = 0;
      }
      fft.run(re, im, inverse: true);
      for (var i = lifter; i <= n - lifter; i++) {
        re[i] = 0;
      }
      for (var i = 0; i < n; i++) {
        im[i] = 0;
      }
      fft.run(re, im, inverse: false);
      for (var b = 0; b < k; b++) {
        env[b] = math.exp(re[b]);
      }

      // ---- source --------------------------------------------------------
      for (var b = 0; b < k; b++) {
        newMag[b] = 0;
        newFreq[b] = binW[b];
      }
      final outPh = sumPh; // reused buffer for output phases
      switch (mode) {
        case SourceMode.natural:
          for (var b = 0; b < k; b++) {
            var d = ph[b] - lastPh[b] - binW[b];
            d -= 2 * math.pi * ((d + math.pi) / (2 * math.pi)).floorToDouble();
            trueFreq[b] = binW[b] + d;
            lastPh[b] = ph[b];
          }
          for (var b = 0; b < k; b++) {
            final j = (b * pitch).round();
            if (j >= k) break;
            newMag[j] += mag[b] / env[b];
            newFreq[j] = trueFreq[b] * pitch;
          }
          for (var b = 0; b < k; b++) {
            sumPh[b] += newFreq[b];
          }
        case SourceMode.whisper:
          for (var b = 0; b < k; b++) {
            newMag[b] = 1;
            sumPh[b] = (rnd.nextDouble() * 2 - 1) * math.pi;
          }
        case SourceMode.monotone:
          final hb = monotoneHz * n / sr;
          for (var h = 1; h * hb < k - 1; h++) {
            final b = (h * hb).round();
            newMag[b] += 1.5;
            newFreq[b] = 2 * math.pi * h * monotoneHz * hop / sr;
          }
          for (var b = 0; b < k; b++) {
            sumPh[b] += newFreq[b];
          }
      }

      // ---- warp envelope (formants) --------------------------------------
      for (var b = 0; b < k; b++) {
        final src = b / formant;
        final i0 = src.floor();
        if (i0 >= k - 1) {
          envOut[b] = env[k - 1];
        } else {
          final f = src - i0;
          envOut[b] = env[i0] * (1 - f) + env[i0 + 1] * f;
        }
      }

      var gain = 1.0;
      if (gateRef > 0) {
        final rms = math.sqrt(energy / n);
        final t = (rms / (gateRef * 0.08)).clamp(0.0, 1.0);
        gain = t * t;
      }

      // ---- synthesis -----------------------------------------------------
      for (var b = 0; b < k; b++) {
        final m = newMag[b] * envOut[b] * gain;
        re[b] = m * math.cos(outPh[b]);
        im[b] = m * math.sin(outPh[b]);
      }
      for (var b = 1; b < half; b++) {
        re[n - b] = re[b];
        im[n - b] = -im[b];
      }
      im[0] = 0;
      im[half] = 0;
      fft.run(re, im, inverse: true);
      for (var i = 0; i < n; i++) {
        out[pos + i] += re[i] * win[i] / 1.5;
      }
    }

    final y = Float32List(x.length);
    for (var i = 0; i < x.length; i++) {
      y[i] = out[i + n];
    }
    return y;
  }

  static double _maxFrameRms(Float32List x, int n, int hop) {
    var best = 0.0;
    for (var pos = 0; pos < x.length; pos += hop) {
      final end = math.min(pos + n, x.length);
      var s = 0.0;
      for (var i = pos; i < end; i++) {
        s += x[i] * x[i];
      }
      final r = math.sqrt(s / n);
      if (r > best) best = r;
    }
    return best;
  }
}

/// In-place iterative radix-2 complex FFT. `inverse` includes the 1/n scale.
class _Fft {
  _Fft(this.n)
      : _cos = Float64List(n ~/ 2),
        _sin = Float64List(n ~/ 2),
        _rev = Int32List(n) {
    for (var i = 0; i < n ~/ 2; i++) {
      _cos[i] = math.cos(2 * math.pi * i / n);
      _sin[i] = math.sin(2 * math.pi * i / n);
    }
    var bits = 0;
    while ((1 << bits) < n) {
      bits++;
    }
    for (var i = 0; i < n; i++) {
      var r = 0;
      for (var b = 0; b < bits; b++) {
        if (i & (1 << b) != 0) r |= 1 << (bits - 1 - b);
      }
      _rev[i] = r;
    }
  }

  final int n;
  final Float64List _cos, _sin;
  final Int32List _rev;

  void run(Float64List re, Float64List im, {required bool inverse}) {
    for (var i = 0; i < n; i++) {
      final j = _rev[i];
      if (j > i) {
        final tr = re[i];
        re[i] = re[j];
        re[j] = tr;
        final ti = im[i];
        im[i] = im[j];
        im[j] = ti;
      }
    }
    final sign = inverse ? 1.0 : -1.0;
    for (var size = 2; size <= n; size <<= 1) {
      final halfSize = size >> 1;
      final step = n ~/ size;
      for (var start = 0; start < n; start += size) {
        var t = 0;
        for (var j = start; j < start + halfSize; j++) {
          final wr = _cos[t], wi = sign * _sin[t];
          final l = j + halfSize;
          final xr = re[l] * wr - im[l] * wi;
          final xi = re[l] * wi + im[l] * wr;
          re[l] = re[j] - xr;
          im[l] = im[j] - xi;
          re[j] += xr;
          im[j] += xi;
          t += step;
        }
      }
    }
    if (inverse) {
      final s = 1 / n;
      for (var i = 0; i < n; i++) {
        re[i] *= s;
        im[i] *= s;
      }
    }
  }
}
