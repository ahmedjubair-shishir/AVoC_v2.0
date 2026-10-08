import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/motion/motion.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/page_indicator.dart';
import '../shell/app_shell.dart';
import 'widgets/onboarding_illustrations.dart';

/// Figma "09 · Onboarding 1–3" (14:18, 14:47, 14:96 + dark).
///
/// Flow (prototype notes):
/// * Shown on first launch only. Skip or Get Started → Home, never shown again.
/// * Auto-advances every 4s until the user interacts (swipe, dots, buttons).
/// * Next, page dots and swipe left/right all work.
/// * Screens 2–3 have a Previous arrow; Skip is on screens 1–2.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Page {
  const _Page(this.title, this.body, this.illustration);
  final String title;
  final String body;
  final Widget illustration;
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _autoAdvanceEvery = Duration(seconds: 4);

  static const _pages = [
    _Page(
      'Record your voice',
      'Record a short voice clip and turn it into a different voice.',
      MicIllustration(),
    ),
    _Page(
      'Choose your voice',
      'Preview different voice styles and pick the one you like.',
      VoiceChipsIllustration(),
    ),
    _Page(
      'Listen, save, and share',
      'Compare the original and changed voice, then save or share your result.',
      ComparePlayersIllustration(),
    ),
  ];

  final _controller = PageController();
  int _index = 0;
  Timer? _auto;
  bool _userTookOver = false;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _auto = Timer.periodic(_autoAdvanceEvery, (_) {
      if (_userTookOver || _isLast) {
        _auto?.cancel();
        return;
      }
      _goTo(_index + 1, byUser: false);
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _stopAuto() {
    _userTookOver = true;
    _auto?.cancel();
  }

  void _goTo(int i, {bool byUser = true}) {
    if (byUser) _stopAuto();
    if (i < 0 || i >= _pages.length) return;
    if (context.reduceMotion) {
      _controller.jumpToPage(i);
    } else {
      _controller.animateToPage(
        i,
        duration: AppMotion.slow,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    _stopAuto();
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppRoutes.fade(const AppShell(), reduceMotion: context.reduceMotion),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = context.reduceMotion ? Duration.zero : AppMotion.fast;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: 56dp, left 4 / right 8.
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: Row(
                  children: [
                    AnimatedOpacity(
                      opacity: _index > 0 ? 1 : 0,
                      duration: d,
                      child: IgnorePointer(
                        ignoring: _index == 0,
                        child: AppIconButton(
                          icon: LucideIcons.arrowLeft,
                          tooltip: 'Previous',
                          onPressed: () => _goTo(_index - 1),
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _isLast ? 0 : 1,
                      duration: d,
                      child: IgnorePointer(
                        ignoring: _isLast,
                        child: AppTextButton(label: 'Skip', onPressed: _finish),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Body: swipeable pages.
            Expanded(
              child: NotificationListener<ScrollStartNotification>(
                onNotification: (n) {
                  if (n.dragDetails != null) _stopAuto(); // user swiped
                  return false;
                },
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _OnboardingPage(page: _pages[i]),
                ),
              ),
            ),
            // Footer: top 16, bottom 32, sides 16, gap 24.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                children: [
                  // Dots are 8dp tall; the extra tap padding overflows invisibly.
                  SizedBox(
                    height: 8,
                    child: OverflowBox(
                      maxHeight: 32,
                      child: PageIndicator(
                        count: _pages.length,
                        index: _index,
                        onSelect: _goTo,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: d,
                    child: PrimaryButton(
                      key: ValueKey(_isLast),
                      label: _isLast ? 'Get Started' : 'Next',
                      onPressed: _isLast ? _finish : () => _goTo(_index + 1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Centered vertically like Figma; scrolls only if text is very large.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 280,
                  child: Center(child: page.illustration),
                ),
                const SizedBox(height: 48), // 12 gap + 24 spacer + 12 gap
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: AppText.headline.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  page.body,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
