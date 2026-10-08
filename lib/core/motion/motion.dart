import 'package:flutter/widgets.dart';

/// Motion tokens. Every animation in the app uses these, so timing feels
/// consistent and can be tuned in one place.
abstract final class AppMotion {
  static const press = Duration(milliseconds: 90);
  static const release = Duration(milliseconds: 260);
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);

  /// Things arriving on screen.
  static const enter = Curves.easeOutCubic;

  /// Springy settle after a press or selection.
  static const settle = Curves.easeOutBack;

  /// Things leaving the screen.
  static const exit = Curves.easeInCubic;
}

extension ReduceMotionX on BuildContext {
  /// True when the user turned on "Remove animations" in Android accessibility
  /// settings (spec §40: respect reduced motion).
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;
}
