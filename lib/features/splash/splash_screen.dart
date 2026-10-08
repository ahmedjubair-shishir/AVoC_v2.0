import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/motion.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_logo.dart';
import '../onboarding/onboarding_screen.dart';
import '../shell/app_shell.dart';

/// Figma "09 · Splash" (14:2 / 14:160).
///
/// Flow (prototype notes): auto-advances after 2s, tap anywhere to skip.
/// First launch → Onboarding, afterwards → Home.
///
/// Motion: logo pops in, its 5 bars grow one by one, then the name and
/// tagline lift in.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _autoAdvance = Duration(seconds: 2);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final _logo = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.45, curve: Curves.easeOutBack),
  );
  late final _logoFade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.25, curve: Curves.easeOut),
  );
  late final _bars = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.15, 0.85, curve: Curves.linear),
  );
  late final _title = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.35, 0.8, curve: AppMotion.enter),
  );
  late final _tagline = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.5, 1, curve: AppMotion.enter),
  );

  Timer? _timer;
  bool _started = false;
  bool _left = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (context.reduceMotion) {
      _c.value = 1;
    } else {
      _c.forward();
    }
    _timer = Timer(_autoAdvance, _next);
  }

  void _next() {
    if (_left || !mounted) return;
    _left = true;
    _timer?.cancel();
    final seen = ref.read(onboardingSeenProvider);
    Navigator.of(context).pushReplacement(
      AppRoutes.fade(
        seen ? const AppShell() : const OnboardingScreen(),
        reduceMotion: context.reduceMotion,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  Widget _lift(Animation<double> a, Widget child) => AnimatedBuilder(
        animation: a,
        child: child,
        builder: (_, child) => Opacity(
          opacity: a.value,
          child: Transform.translate(
            offset: Offset(0, (1 - a.value) * 12),
            child: child,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next, // tap to skip
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Center(
              child: Semantics(
                label: 'Voice Changer. Give your recording a new voice',
                excludeSemantics: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.7, end: 1.0).animate(_logo),
                        child: AnimatedBuilder(
                          animation: _bars,
                          builder: (_, _) => AppLogo(progress: _bars.value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _lift(
                      _title,
                      Text(
                        'Voice Changer',
                        style: AppText.headline.copyWith(color: c.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _lift(
                      _tagline,
                      Text(
                        'Give your recording a new voice',
                        style: AppText.body.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
