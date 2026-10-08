import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/lucide_glyphs.dart';
import '../recordings/voice_style.dart';

/// Figma "Voice card" (21:377). Tap card = select (border + tint + check,
/// never color alone). The round button previews the voice.
class VoiceCard extends StatelessWidget {
  const VoiceCard({
    super.key,
    required this.voice,
    required this.selected,
    required this.previewing,
    required this.preparing,
    required this.progress,
    required this.onSelect,
    required this.onPreview,
  });

  final VoiceStyle voice;
  final bool selected;
  final bool previewing;
  final bool preparing;
  final double progress;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = context.reduceMotion ? Duration.zero : AppMotion.medium;
    final b = selected ? 1.0 : 0.0; // border grows 1→2, padding shrinks 1

    return Semantics(
      button: true,
      selected: selected,
      label: 'Select ${voice.label} voice. ${voice.description}',
      child: Pressable(
        scale: 0.97,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect();
          },
          child: AnimatedContainer(
            duration: d,
            curve: AppMotion.enter,
            padding: EdgeInsets.fromLTRB(12 - b, 12 - b, 8 - b, 16 - b),
            decoration: BoxDecoration(
              color: selected ? c.primaryContainer : c.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? c.primary : c.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedContainer(
                      duration: d,
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected ? c.surface : c.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      alignment: Alignment.center,
                      child: Icon(voice.icon, size: 22, color: c.onPrimaryContainer),
                    ),
                    _PreviewButton(
                      voice: voice,
                      selected: selected,
                      playing: previewing,
                      preparing: preparing,
                      onTap: onPreview,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          voice.label,
                          style: AppText.bodyStrong.copyWith(color: c.textPrimary),
                        ),
                      ),
                      AnimatedScale(
                        scale: selected ? 1 : 0,
                        duration: d,
                        curve: AppMotion.settle,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: c.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(LucideIcons.check, size: 14, color: c.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: Text(
                    voice.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(color: c.textSecondary),
                  ),
                ),
                AnimatedSize(
                  duration: d,
                  curve: AppMotion.enter,
                  child: previewing
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(
                              height: 4,
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: c.textSecondary,
                                color: c.primary,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 48dp touch target, 36dp visual ("Compact" icon button in Figma).
class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    required this.voice,
    required this.selected,
    required this.playing,
    required this.preparing,
    required this.onTap,
  });

  final VoiceStyle voice;
  final bool selected;
  final bool playing;
  final bool preparing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = context.reduceMotion ? Duration.zero : AppMotion.fast;
    final bg = playing ? c.primary : (selected ? c.surface : c.surfaceRaised);
    return Semantics(
      button: true,
      label: playing ? 'Stop ${voice.label} voice' : 'Preview ${voice.label} voice',
      excludeSemantics: true,
      child: Pressable(
        scale: 0.85,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: AnimatedContainer(
                duration: d,
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: preparing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.primary,
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: d,
                        transitionBuilder: (child, a) =>
                            ScaleTransition(scale: a, child: child),
                        child: playing
                            ? PauseGlyph(
                                key: const ValueKey('p'),
                                size: 16,
                                color: c.onPrimary,
                              )
                            : PlayGlyph(
                                key: const ValueKey('l'),
                                size: 16,
                                color: c.textPrimary,
                              ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
