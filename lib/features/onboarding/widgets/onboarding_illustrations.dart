import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/motion.dart';
import '../../../core/motion/pressable.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/lucide_glyphs.dart';

/// Onboarding 1 illustration (Figma 14:30): 240 circle, 176 inner circle,
/// 72dp mic. Motion: slow "breathing" ring, like a live microphone.
class MicIllustration extends StatefulWidget {
  const MicIllustration({super.key});

  @override
  State<MicIllustration> createState() => _MicIllustrationState();
}

class _MicIllustrationState extends State<MicIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
      _c.value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        width: 240,
        height: 240,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final t = Curves.easeInOut.transform(_c.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 0.94 + 0.06 * t,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.primary.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Container(
                  width: 176,
                  height: 176,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.primaryContainer,
                  ),
                ),
                Icon(LucideIcons.mic, size: 72, color: c.onPrimaryContainer),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Onboarding 2 illustration (Figma 14:58): three voice chips, one selected.
/// Interactive: tap a chip to select it.
class VoiceChipsIllustration extends StatefulWidget {
  const VoiceChipsIllustration({super.key});

  @override
  State<VoiceChipsIllustration> createState() => _VoiceChipsIllustrationState();
}

class _VoiceChipsIllustrationState extends State<VoiceChipsIllustration> {
  static const _chips = [
    ('Deep', LucideIcons.chevronsDown),
    ('Robot', LucideIcons.bot),
    ('Cartoon', LucideIcons.smile),
  ];
  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _chips.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _VoiceChip(
            label: _chips[i].$1,
            icon: _chips[i].$2,
            selected: i == _selected,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selected = i);
            },
          ),
        ],
      ],
    );
  }
}

class _VoiceChip extends StatelessWidget {
  const _VoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = context.reduceMotion ? Duration.zero : AppMotion.medium;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label voice',
      excludeSemantics: true,
      child: Pressable(
        scale: 0.97,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: d,
            curve: AppMotion.enter,
            width: 248,
            // Border width changes 1→2, so padding shrinks by 1 to keep size.
            padding: EdgeInsets.fromLTRB(
              selected ? 11 : 12, selected ? 11 : 12,
              selected ? 15 : 16, selected ? 11 : 12,
            ),
            decoration: BoxDecoration(
              color: selected ? c.primaryContainer : c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? c.primary : c.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: d,
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? c.surface : c.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 20, color: c.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppText.bodyStrong.copyWith(color: c.textPrimary),
                  ),
                ),
                AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: d,
                  curve: AppMotion.settle,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(LucideIcons.check, size: 16, color: c.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Onboarding 3 illustration (Figma 14:105): Original vs Robot mini players.
/// Interactive: tap a player to "play" it (bars animate).
class ComparePlayersIllustration extends StatefulWidget {
  const ComparePlayersIllustration({super.key});

  @override
  State<ComparePlayersIllustration> createState() =>
      _ComparePlayersIllustrationState();
}

class _ComparePlayersIllustrationState
    extends State<ComparePlayersIllustration> {
  int _playing = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MiniPlayer(
          label: 'Original',
          playing: _playing == 0,
          onTap: () => setState(() => _playing = _playing == 0 ? -1 : 0),
        ),
        const SizedBox(height: 12),
        _MiniPlayer(
          label: 'Robot',
          playing: _playing == 1,
          onTap: () => setState(() => _playing = _playing == 1 ? -1 : 1),
        ),
      ],
    );
  }
}

class _MiniPlayer extends StatefulWidget {
  const _MiniPlayer({
    required this.label,
    required this.playing,
    required this.onTap,
  });

  final String label;
  final bool playing;
  final VoidCallback onTap;

  @override
  State<_MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<_MiniPlayer>
    with SingleTickerProviderStateMixin {
  static const List<double> _heights = [
    8.0, 16, 22.4, 12.8, 25.6, 19.2, 28.8, 14.4, 22.4, 11.2, 19.2, 24, 12.8, 17.6,
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(_MiniPlayer old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    if (widget.playing && !context.reduceMotion) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final on = widget.playing;
    final d = context.reduceMotion ? Duration.zero : AppMotion.medium;
    final barColor = on ? c.primary : c.textSecondary;
    return Semantics(
      button: true,
      label: '${on ? 'Pause' : 'Play'} ${widget.label.toLowerCase()} sample',
      excludeSemantics: true,
      child: Pressable(
        scale: 0.97,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: d,
            curve: AppMotion.enter,
            width: 264,
            padding: EdgeInsets.fromLTRB(on ? 11 : 12, on ? 11 : 12,
                on ? 15 : 16, on ? 11 : 12),
            decoration: BoxDecoration(
              color: on ? c.primaryContainer : c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: on ? c.primary : c.border,
                width: on ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: d,
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: on ? c.primary : c.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: d,
                    transitionBuilder: (child, a) =>
                        ScaleTransition(scale: a, child: child),
                    child: on
                        ? PauseGlyph(
                            key: const ValueKey('pause'),
                            size: 18,
                            color: c.onPrimary,
                          )
                        : PlayGlyph(
                            key: const ValueKey('play'),
                            size: 18,
                            color: c.onPrimaryContainer,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: d,
                        style: AppText.label.copyWith(
                          color: on ? c.onPrimaryContainer : c.textSecondary,
                        ),
                        child: Text(widget.label),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 29,
                        child: AnimatedBuilder(
                          animation: _c,
                          builder: (_, _) => Row(
                            children: [
                              for (var i = 0; i < _heights.length; i++) ...[
                                if (i > 0) const SizedBox(width: 4),
                                Container(
                                  width: 4,
                                  height: _barHeight(i),
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _barHeight(int i) {
    final base = _heights[i];
    if (!_c.isAnimating) return base;
    final wobble = math.sin((_c.value * 2 * math.pi) + i * 0.9);
    return (base * (0.75 + 0.25 * wobble)).clamp(4.0, 28.8).toDouble();
  }
}
