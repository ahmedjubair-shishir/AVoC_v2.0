import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'app_buttons.dart';

/// One button in a dialog's action row.
class DialogAction<T> {
  const DialogAction(this.label, this.value,
      {this.tone = TextButtonTone.primary});

  final String label;
  final T value;
  final TextButtonTone tone;
}

/// Figma "Dialog": radius 20, centered over a 55% scrim. Tapping the scrim
/// returns null (same as the dismiss button, per prototype notes).
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required String title,
  required String body,
  required List<DialogAction<T>> actions,
}) {
  final c = context.colors;
  HapticFeedback.mediumImpact();
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: c.scrim,
    transitionDuration: context.reduceMotion ? Duration.zero : AppMotion.medium,
    pageBuilder: (ctx, _, _) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Material(
            color: c.surfaceOverlay,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppText.title.copyWith(color: c.textPrimary)),
                  const SizedBox(height: 12),
                  Text(body,
                      style: AppText.body.copyWith(color: c.textSecondary)),
                  const SizedBox(height: 12 + 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 4,
                      children: [
                        for (final a in actions)
                          AppTextButton(
                            label: a.label,
                            tone: a.tone,
                            onPressed: () => Navigator.of(ctx).pop(a.value),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, anim, _, child) {
      final t = CurvedAnimation(parent: anim, curve: AppMotion.enter);
      return FadeTransition(
        opacity: t,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(t),
          child: child,
        ),
      );
    },
  );
}

/// Figma "Bottom sheet": surface/overlay, top radius 28, drag handle.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final c = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.surfaceOverlay,
    barrierColor: c.scrim,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (ctx) => Padding(
      // Lifts the sheet above the keyboard (Save / Rename fields).
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: builder(ctx),
    ),
  );
}

/// Figma "Drag handle": 32×4 in a 20dp row.
class DragHandle extends StatelessWidget {
  const DragHandle({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 20,
        child: Center(
          child: Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
}

/// Figma "Snackbar": inverse surface, optional icon and one action, 4s.
void showAppSnack(
  BuildContext context,
  String message, {
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final c = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        content: SizedBox(
          height: 48,
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: c.onInverseSurface),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  message,
                  style: AppText.body.copyWith(color: c.onInverseSurface),
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onAction?.call();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: c.inversePrimary,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: AppText.bodyStrong,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(actionLabel),
                ),
            ],
          ),
        ),
      ),
    );
}

/// Shortcut for error snackbars with the circle-alert icon.
void showErrorSnack(BuildContext context, String message,
        {String? actionLabel, VoidCallback? onAction}) =>
    showAppSnack(context, message,
        icon: LucideIcons.circleAlert,
        actionLabel: actionLabel,
        onAction: onAction);
