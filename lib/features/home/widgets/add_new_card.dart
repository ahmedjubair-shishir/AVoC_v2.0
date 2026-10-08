import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/pressable.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/level_bars.dart';

/// Home hero: the main "Add New" action (Figma node 4:17).
///
/// Motion: card squishes on touch, the level bars grow in on first show and
/// ripple once on tap, and the mic badge gives a small bounce.
class AddNewCard extends StatefulWidget {
  const AddNewCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<AddNewCard> createState() => _AddNewCardState();
}

class _AddNewCardState extends State<AddNewCard> {
  final _bars = GlobalKey<LevelBarsState>();
  int _taps = 0;

  void _handleTap() {
    HapticFeedback.lightImpact();
    _bars.currentState?.pulse();
    setState(() => _taps++);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: 'Add new recording',
      excludeSemantics: true,
      child: Pressable(
        child: Material(
          color: c.primary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _handleTap,
            splashColor: c.onPrimary.withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s24, AppSpace.s20, AppSpace.s24, AppSpace.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Replays a small bounce on every tap.
                      TweenAnimationBuilder<double>(
                        key: ValueKey(_taps),
                        tween: Tween<double>(begin: _taps == 0 ? 1.0 : 0.85, end: 1.0),
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.elasticOut,
                        builder: (_, s, child) =>
                            Transform.scale(scale: s, child: child),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: c.onPrimary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child:
                              Icon(LucideIcons.mic, size: 28, color: c.primary),
                        ),
                      ),
                      LevelBars(
                        key: _bars,
                        color: c.onPrimary,
                        introDelay: const Duration(milliseconds: 250),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s20),
                  Row(
                    children: [
                      Icon(LucideIcons.plus, size: 24, color: c.onPrimary),
                      const SizedBox(width: AppSpace.s8),
                      Text(
                        'Add New',
                        style: AppText.headline.copyWith(color: c.onPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    'Record your voice and transform it.',
                    style: AppText.body.copyWith(color: c.onPrimary),
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
