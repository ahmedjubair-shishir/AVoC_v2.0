import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';

/// Top-level layout with the Figma "Navigation bar": Home and History.
///
/// Tabs keep their scroll position and cross-fade with a small lift when
/// switching.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _go(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(onSeeAll: () => _go(1)),
      const HistoryScreen(),
    ];
    return Scaffold(
      body: _FadeThroughStack(index: _index, children: tabs),
      bottomNavigationBar: _NavBar(index: _index, onSelect: _go),
    );
  }
}

/// Like IndexedStack, but fades/lifts between children.
class _FadeThroughStack extends StatelessWidget {
  const _FadeThroughStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final d = context.reduceMotion ? Duration.zero : AppMotion.medium;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final i in [
          for (var j = 0; j < children.length; j++)
            if (j != index) j,
          index,
        ])
          // The selected tab is painted last (on top). The fade itself must
          // keep ticking, so TickerMode only pauses the tab's *content*.
          IgnorePointer(
            key: ValueKey(i), // keeps each tab's state when reordered
            ignoring: i != index,
            child: ExcludeSemantics(
              excluding: i != index,
              child: AnimatedOpacity(
                opacity: i == index ? 1 : 0,
                duration: d,
                curve: i == index ? AppMotion.enter : AppMotion.exit,
                child: AnimatedSlide(
                  offset: i == index ? Offset.zero : const Offset(0, 0.015),
                  duration: d,
                  curve: AppMotion.enter,
                  child: TickerMode(
                    enabled: i == index,
                    child: children[i],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        // Figma: 80dp bar. Content (32 pill + 4 + 20 label) is 56dp, so
        // 12dp above and below. Grows if the user picks larger text.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(
                icon: LucideIcons.house,
                label: 'Home',
                selected: index == 0,
                onTap: () => onSelect(0),
              ),
              _NavItem(
                icon: LucideIcons.history,
                label: 'History',
                selected: index == 1,
                onTap: () => onSelect(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selected state = pill indicator + stronger label (Figma: not color alone).
/// Motion: the pill stretches open from the icon and the icon pops slightly.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.textPrimary : c.textSecondary;
    final d = context.reduceMotion ? Duration.zero : AppMotion.medium;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Pressable(
            scale: 0.92,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 64,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: d,
                          curve: AppMotion.settle,
                          width: selected ? 64 : 24,
                          height: 32,
                          decoration: BoxDecoration(
                            color: selected
                                ? c.primaryContainer
                                : c.primaryContainer.withValues(alpha: 0),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                        AnimatedScale(
                          scale: selected ? 1.0 : 0.92,
                          duration: d,
                          curve: AppMotion.settle,
                          child: Icon(icon, size: 24, color: fg),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.s4),
                  AnimatedDefaultTextStyle(
                    duration: d,
                    style: AppText.label.copyWith(color: fg),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
