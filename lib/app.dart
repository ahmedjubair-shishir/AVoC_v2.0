import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/prefs.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

/// App flow (Figma prototype notes, see docs/FLOW.md):
///   Splash ──2s / tap──▶ Onboarding (first launch only) ──▶ Home
///   Home ── Add New ──▶ Permission ▶ Recording ▶ Preview ▶ Voice ▶ Converting ▶ Result ▶ Saved
class AvocApp extends ConsumerWidget {
  const AvocApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Voice Changer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      // Status/navigation bar icons follow the theme on every screen,
      // including ones without an app bar (Splash, Onboarding).
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final c = context.colors;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
            systemNavigationBarIconBrightness:
                dark ? Brightness.light : Brightness.dark,
          ),
          child: ColoredBox(color: c.bg, child: child),
        );
      },
      home: const SplashScreen(),
    );
  }
}
