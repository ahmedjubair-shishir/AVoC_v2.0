import 'dart:typed_data';

import '../../features/recordings/voice_style.dart';
import 'dsp.dart';
import 'spectral.dart';

/// Turns a recording into one of the voice styles. Pure Dart, runs offline.
///
/// This is the only place that knows *how* each voice sounds, so it can be
/// swapped for a cloud/AI engine later without touching any screen.
///
/// Two kinds of pitch change are used on purpose:
/// * [VoiceShaper] moves pitch and formants separately → sounds like a
///   different *person* (Female, Male, Baby, Giant…).
/// * [Dsp.pitchShift] moves both together like a sped-up tape → sounds like
///   a *cartoon* (Chipmunk, Cartoon).
abstract final class VoiceEffects {
  static Float32List apply(VoiceStyle voice, Float32List x, int sr) {
    Float32List y;
    switch (voice) {
      // ---- Gender ---------------------------------------------------------
      case VoiceStyle.female:
        // ≈ +6 semitones, ~17% smaller vocal tract.
        y = VoiceShaper.process(x, sr, pitch: 1.42, formant: 1.17);
        y = Dsp.highPass(y, sr, 140);
        y = Dsp.peak(y, sr, 3200, 2, q: 0.8); // a little air/brightness
      case VoiceStyle.male:
        // ≈ −6.5 semitones, ~14% larger vocal tract.
        y = VoiceShaper.process(x, sr, pitch: 0.69, formant: 0.86);
        y = Dsp.peak(y, sr, 140, 3);
        y = Dsp.lowPass(y, sr, 7500);
      case VoiceStyle.deep:
        y = VoiceShaper.process(x, sr, pitch: 0.78, formant: 0.92);
        y = Dsp.peak(y, sr, 160, 3);
        y = Dsp.lowPass(y, sr, 7000);
      case VoiceStyle.high:
        y = VoiceShaper.process(x, sr, pitch: 1.3, formant: 1.08);
        y = Dsp.highPass(y, sr, 120);

      // ---- Characters -----------------------------------------------------
      case VoiceStyle.baby:
        y = VoiceShaper.process(x, sr, pitch: 1.78, formant: 1.38);
        y = Dsp.vibrato(y, sr, rateHz: 7, depthMs: 0.25);
        y = Dsp.highPass(y, sr, 200);
      case VoiceStyle.chipmunk:
        y = Dsp.pitchShift(x, sr, 1.95, windowMs: 30);
        y = Dsp.highPass(y, sr, 180);
      case VoiceStyle.cartoon:
        y = Dsp.pitchShift(x, sr, 1.65, windowMs: 35);
        y = Dsp.vibrato(y, sr, rateHz: 5, depthMs: 0.6);
      case VoiceStyle.elf:
        final base = VoiceShaper.process(x, sr, pitch: 1.5, formant: 1.25);
        final sparkle = VoiceShaper.process(x, sr, pitch: 2.0, formant: 1.5);
        y = Dsp.mix(Dsp.normalize(base),
            Dsp.normalize(Dsp.highPass(sparkle, sr, 1500)), 0.3);
        y = Dsp.reverb(y, sr, size: 0.55, damp: 0.2, mix: 0.25, tailSeconds: 1);
      case VoiceStyle.oldMan:
        y = VoiceShaper.process(x, sr, pitch: 0.9, formant: 0.95);
        y = Dsp.vibrato(y, sr, rateHz: 5.5, depthMs: 0.9); // shaky pitch
        y = Dsp.tremolo(y, sr, rateHz: 5.5, depth: 0.25);
        y = Dsp.highPass(y, sr, 220);
        y = Dsp.lowPass(y, sr, 4800);
        y = Dsp.noise(y, 0.002);
      case VoiceStyle.giant:
        y = VoiceShaper.process(x, sr, pitch: 0.58, formant: 0.72);
        y = Dsp.peak(y, sr, 110, 5);
        y = Dsp.lowPass(y, sr, 5000);
        y = Dsp.reverb(y, sr, size: 0.85, damp: 0.5, mix: 0.3, tailSeconds: 2);
      case VoiceStyle.monster:
        y = VoiceShaper.process(x, sr, pitch: 0.6, formant: 0.78);
        y = Dsp.softClip(Dsp.normalize(y), 2.2);
        y = Dsp.lowPass(y, sr, 4000);
        y = Dsp.echo(y, sr, delaySeconds: 0.06, feedback: 0.25, mix: 0.25);
      case VoiceStyle.ghost:
        final breath = VoiceShaper.process(x, sr,
            mode: SourceMode.whisper, formant: 0.9);
        final moan = VoiceShaper.process(x, sr, pitch: 0.75, formant: 0.9);
        y = Dsp.mix(Dsp.normalize(breath),
            Dsp.normalize(Dsp.lowPass(moan, sr, 1200)), 0.3);
        y = Dsp.vibrato(y, sr, rateHz: 0.7, depthMs: 4);
        y = Dsp.reverb(y, sr, size: 0.95, damp: 0.35, mix: 0.55, tailSeconds: 2.5);

      // ---- Sci-fi ---------------------------------------------------------
      case VoiceStyle.robot:
        y = Dsp.ringMod(x, sr, 70, 0.7);
        y = Dsp.echo(y, sr, delaySeconds: 0.006, feedback: 0.55, mix: 0.6);
        y = Dsp.highPass(y, sr, 100);
      case VoiceStyle.aiAssistant:
        y = VoiceShaper.process(x, sr,
            mode: SourceMode.monotone, monotoneHz: 150, formant: 1.04);
        y = Dsp.mix(y, Dsp.vibrato(y, sr, rateHz: 0.4, depthMs: 0.8), 0.5);
        y = Dsp.highPass(y, sr, 120);
        y = Dsp.echo(y, sr, delaySeconds: 0.045, feedback: 0.2, mix: 0.18);
      case VoiceStyle.alien:
        y = Dsp.pitchShift(x, sr, 1.18, windowMs: 40);
        y = Dsp.ringMod(y, sr, 330, 0.35);
        y = Dsp.vibrato(y, sr, rateHz: 6, depthMs: 1.5);

      // ---- Effects --------------------------------------------------------
      case VoiceStyle.whisper:
        y = VoiceShaper.process(x, sr, mode: SourceMode.whisper);
        y = Dsp.highPass(y, sr, 300);
        y = Dsp.peak(y, sr, 5000, 3);
      case VoiceStyle.megaphone:
        y = Dsp.highPass(x, sr, 500);
        y = Dsp.lowPass(y, sr, 3800);
        y = Dsp.peak(y, sr, 1800, 8, q: 1.2);
        y = Dsp.softClip(Dsp.normalize(y), 6);
        y = Dsp.echo(y, sr, delaySeconds: 0.0025, feedback: 0.4, mix: 0.4);
        y = Dsp.lowPass(y, sr, 4500);
      case VoiceStyle.radio:
        y = Dsp.highPass(x, sr, 350);
        y = Dsp.lowPass(y, sr, 3200);
        y = Dsp.peak(y, sr, 1500, 4);
        y = Dsp.softClip(y, 2.5);
        y = Dsp.noise(y, 0.004);
      case VoiceStyle.echo:
        y = Dsp.echo(x, sr,
            delaySeconds: 0.28, feedback: 0.45, mix: 0.55, tailSeconds: 1.0);
      case VoiceStyle.underwater:
        y = Dsp.pitchShift(x, sr, 0.94, windowMs: 60);
        y = Dsp.lowPass(y, sr, 700, q: 1.4);
        y = Dsp.lowPass(y, sr, 900);
        y = Dsp.vibrato(y, sr, rateHz: 1.3, depthMs: 3);
        y = Dsp.normalize(y, target: 0.7);
        y = Dsp.bubbles(y, sr, level: 0.05);
        y = Dsp.reverb(y, sr, size: 0.5, damp: 0.8, mix: 0.3, tailSeconds: 0.8);
    }
    return Dsp.normalize(y);
  }
}
