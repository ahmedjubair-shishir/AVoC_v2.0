import 'package:flutter/material.dart';

import '../motion/entrance.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shared layout for full-screen states (permission, too short, no audio,
/// conversion failed, saved): centered badge + headline + body, with an
/// actions footer (top 16, bottom 32, sides 16).
class StatusBody extends StatelessWidget {
  const StatusBody({
    super.key,
    required this.badge,
    required this.title,
    required this.body,
    this.gap = 16,
    this.extra,
  });

  final Widget badge;
  final String title;
  final String body;

  /// Figma uses 16 on permission screens and 12 on others.
  final double gap;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Entrance(child: badge),
                SizedBox(height: gap + 8 + gap),
                Entrance(
                  delay: const Duration(milliseconds: 60),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppText.headline.copyWith(color: c.textPrimary),
                  ),
                ),
                SizedBox(height: gap),
                Entrance(
                  delay: const Duration(milliseconds: 120),
                  child: Text(
                    body,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: c.textSecondary),
                  ),
                ),
                if (extra != null) ...[
                  SizedBox(height: gap + 12 + gap),
                  Entrance(
                    delay: const Duration(milliseconds: 180),
                    child: extra!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Footer with stacked actions.
class ActionsFooter extends StatelessWidget {
  const ActionsFooter({
    super.key,
    required this.children,
    this.gap = 8,
    this.top = 16,
    this.bottom = 32,
  });

  final List<Widget> children;
  final double gap;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, top, 16, bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
