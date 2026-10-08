import 'package:flutter/material.dart';

import '../motion/motion.dart';

/// Shared page transitions so every screen change feels the same.
abstract final class AppRoutes {
  /// Soft cross-fade with a tiny settle. Used for Splash → Onboarding → Home.
  static Route<T> fade<T>(Widget page, {bool reduceMotion = false}) {
    return PageRouteBuilder<T>(
      transitionDuration: reduceMotion ? Duration.zero : AppMotion.slow,
      reverseTransitionDuration: reduceMotion ? Duration.zero : AppMotion.medium,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, anim, _, child) {
        final t = CurvedAnimation(parent: anim, curve: AppMotion.enter);
        return FadeTransition(
          opacity: t,
          child: ScaleTransition(
            scale: Tween(begin: 1.02, end: 1.0).animate(t),
            child: child,
          ),
        );
      },
    );
  }
}
