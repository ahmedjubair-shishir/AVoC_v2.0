import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/pressable.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/audio_player_card.dart';
import '../format.dart';
import '../recording.dart';

/// Figma component "Recording item": play + title + "Voice · duration · date"
/// + overflow menu. Used in Home › Recent and History.
class RecordingItem extends StatelessWidget {
  const RecordingItem({
    super.key,
    required this.recording,
    required this.whenLabel,
    required this.playing,
    required this.onPlay,
    required this.onMore,
  });

  final Recording recording;

  /// "Today" on Home, "7:20 PM" in History (grouped by day).
  final String whenLabel;
  final bool playing;
  final VoidCallback onPlay;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = recording;
    final meta =
        '${r.voice.label} · ${formatDuration(r.duration)} · $whenLabel';

    return Pressable(
      scale: 0.98,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPlay,
          // Figma: 72dp row with 12dp vertical padding; grows with large text.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s12, AppSpace.s12, AppSpace.s4, AppSpace.s12,
              ),
              child: Row(
                children: [
                  PlayPauseButton(
                    playing: playing,
                    label: '${playing ? 'Pause' : 'Play'} ${r.name}',
                    onTap: onPlay,
                  ),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppText.bodyStrong.copyWith(color: c.textPrimary),
                        ),
                        const SizedBox(height: AppSpace.s4),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppText.caption.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.s12),
                  AppIconButton(
                    icon: LucideIcons.ellipsisVertical,
                    tooltip: 'More options for ${r.name}',
                    onPressed: onMore,
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
