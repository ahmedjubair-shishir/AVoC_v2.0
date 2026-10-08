import 'package:flutter/services.dart';
import 'package:record/record.dart';

/// Microphone permission without extra plugins:
/// the `record` package shows Android's prompt, and a tiny native channel
/// (MainActivity.kt) checks the status and opens the app's Settings page.
abstract final class MicPermission {
  static const _channel = MethodChannel('avoc/system');

  static Future<bool> isGranted() async {
    try {
      return await _channel.invokeMethod<bool>('micGranted') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Shows Android's permission prompt (if Android still allows asking).
  static Future<bool> request() async {
    final rec = AudioRecorder();
    try {
      return await rec.hasPermission();
    } catch (_) {
      return false;
    } finally {
      await rec.dispose();
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod<bool>('openAppSettings');
    } catch (_) {}
  }
}
