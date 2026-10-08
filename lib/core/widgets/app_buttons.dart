import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion/pressable.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

void _tap(VoidCallback? f, {bool strong = false}) {
  if (f == null) return;
  strong ? HapticFeedback.lightImpact() : HapticFeedback.selectionClick();
  f();
}

/// Figma "Button/Primary": 52dp (Large) or 48dp (Medium), radius 16.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null && !loading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        scale: enabled ? 0.98 : 1,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: enabled || loading ? 1 : 0.4,
          child: Material(
            color: c.primary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? () => _tap(onPressed, strong: true) : null,
              splashColor: c.onPrimary.withValues(alpha: 0.14),
              highlightColor: c.onPrimary.withValues(alpha: 0.06),
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: Center(
                  child: loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: c.onPrimary,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, size: 20, color: c.onPrimary),
                              const SizedBox(width: AppSpace.s8),
                            ],
                            Text(
                              label,
                              style: AppText.bodyStrong
                                  .copyWith(color: c.onPrimary),
                            ),
                          ],
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

/// Figma "Button/Secondary": 52dp, 1.5px text/secondary outline,
/// primary/strong label, optional 20dp leading icon.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        scale: 0.98,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(color: c.textSecondary, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed == null ? null : () => _tap(onPressed),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: c.primaryStrong),
                      const SizedBox(width: AppSpace.s8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppText.bodyStrong.copyWith(color: c.primaryStrong),
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

enum TextButtonTone { primary, neutral, destructive }

/// Figma "Button/Text": 48dp pill, 16 padding. Tone: primary/strong
/// (default), neutral = text/secondary (Cancel), destructive = status/error.
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = TextButtonTone.primary,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final TextButtonTone tone;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (tone) {
      TextButtonTone.primary => c.primaryStrong,
      TextButtonTone.neutral => c.textSecondary,
      TextButtonTone.destructive => c.error,
    };
    return Pressable(
      scale: 0.95,
      child: TextButton(
        onPressed: onPressed == null ? null : () => _tap(onPressed),
        style: TextButton.styleFrom(
          minimumSize: Size(expand ? double.infinity : 48, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
          foregroundColor: color,
          shape: const StadiumBorder(),
          textStyle: AppText.bodyStrong,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: color),
              const SizedBox(width: AppSpace.s8),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// Figma "Icon button" (standard): 48×48 touch target, 24 icon.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.88,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed == null ? null : () => _tap(onPressed),
        icon: Icon(icon, size: 24, color: color ?? context.colors.textPrimary),
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      ),
    );
  }
}
