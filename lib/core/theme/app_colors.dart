import 'package:flutter/material.dart';

/// Color tokens from Figma › Foundations (Light / Dark modes).
/// Names mirror the Figma variables, e.g. `primary/container` → [primaryContainer].
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.primary,
    required this.primaryStrong,
    required this.primaryContainer,
    required this.onPrimary,
    required this.onPrimaryContainer,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.error,
    required this.success,
    required this.surfaceOverlay,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
  });

  final Color bg;
  final Color surface;
  final Color surfaceRaised;
  final Color primary;
  final Color primaryStrong;
  final Color primaryContainer;
  final Color onPrimary;
  final Color onPrimaryContainer;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color error;
  final Color success;

  /// Sheets and dialogs.
  final Color surfaceOverlay;

  /// Snackbars.
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color inversePrimary;

  /// Dimmed layer behind sheets/dialogs (Figma: rgba(13,13,20,.55)).
  Color get scrim => const Color(0x8C0D0D14);

  static const light = AppColors(
    bg: Color(0xFFF8F8FC),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF1F0FA),
    primary: Color(0xFF6C5CE7),
    primaryStrong: Color(0xFF5545C7),
    primaryContainer: Color(0xFFECE9FD),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryContainer: Color(0xFF2A1F7A),
    textPrimary: Color(0xFF17171C),
    textSecondary: Color(0xFF5E5E6B),
    border: Color(0xFFE2E2EA),
    error: Color(0xFFC23B3B),
    success: Color(0xFF1F7A4C),
    surfaceOverlay: Color(0xFFFFFFFF),
    inverseSurface: Color(0xFF2A2A33),
    onInverseSurface: Color(0xFFF5F5F7),
    inversePrimary: Color(0xFFB1A7FF),
  );

  static const dark = AppColors(
    bg: Color(0xFF101014),
    surface: Color(0xFF19191F),
    surfaceRaised: Color(0xFF222229),
    primary: Color(0xFF8B7CFF),
    primaryStrong: Color(0xFFB1A7FF),
    primaryContainer: Color(0xFF2C2754),
    onPrimary: Color(0xFF120F2B),
    onPrimaryContainer: Color(0xFFE6E2FF),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFFB4B4BF),
    border: Color(0xFF34343D),
    error: Color(0xFFFF8A80),
    success: Color(0xFF5FD394),
    surfaceOverlay: Color(0xFF2A2A33),
    inverseSurface: Color(0xFFEDEDF2),
    onInverseSurface: Color(0xFF17171C),
    inversePrimary: Color(0xFF5545C7),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      primary: l(primary, other.primary),
      primaryStrong: l(primaryStrong, other.primaryStrong),
      primaryContainer: l(primaryContainer, other.primaryContainer),
      onPrimary: l(onPrimary, other.onPrimary),
      onPrimaryContainer: l(onPrimaryContainer, other.onPrimaryContainer),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      border: l(border, other.border),
      error: l(error, other.error),
      success: l(success, other.success),
      surfaceOverlay: l(surfaceOverlay, other.surfaceOverlay),
      inverseSurface: l(inverseSurface, other.inverseSurface),
      onInverseSurface: l(onInverseSurface, other.onInverseSurface),
      inversePrimary: l(inversePrimary, other.inversePrimary),
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
