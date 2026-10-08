import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/audio/playback.dart';
import '../../core/motion/entrance.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/icon_badge.dart';
import '../../core/widgets/status_layout.dart';
import '../record/record_flow.dart';
import '../recordings/format.dart';
import '../recordings/recording.dart';
import '../recordings/recording_actions.dart';
import '../recordings/recordings_provider.dart';
import '../recordings/widgets/recording_item.dart';

/// Figma "08 · History" — list grouped by day (13:2), item actions (13:92),
/// delete confirmation (13:227), empty state (13:326).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final all = ref.watch(recordingsProvider);
    final pb = ref.watch(playbackProvider);
    final notifier = ref.read(recordingsProvider.notifier);

    // Group by day, newest first.
    final groups = <String, List<Recording>>{};
    for (final r in all) {
      groups.putIfAbsent(formatRelativeDate(r.createdAt), () => []).add(r);
    }

    return Scaffold(
      appBar: const AppTopBar(title: 'History', nav: TopBarNav.none, large: true),
      body: all.isEmpty
          ? StatusBody(
              badge: IconBadge(
                large: true,
                icon: LucideIcons.mic,
                iconColor: c.textSecondary,
              ),
              title: 'No recordings yet',
              body: 'Your saved recordings will appear here.',
              extra: SizedBox(
                width: 200,
                child: PrimaryButton(
                  label: 'Add New',
                  icon: LucideIcons.plus,
                  onPressed: () => startRecordingFlow(context),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                for (final (gi, entry) in groups.entries.indexed) ...[
                  if (gi > 0) const SizedBox(height: 20),
                  Entrance(
                    delay: Duration(milliseconds: 40 * gi.clamp(0, 6).toInt()),
                    child: Text(
                      entry.key,
                      style: AppText.label.copyWith(color: c.textSecondary),
                    ),
                  ),
                  for (final r in entry.value) ...[
                    const SizedBox(height: 8),
                    Entrance(
                      key: ValueKey(r.id),
                      delay: Duration(milliseconds: 40 * gi.clamp(0, 6).toInt()),
                      child: RecordingItem(
                        recording: r,
                        whenLabel: formatTime(r.createdAt),
                        playing: pb.isPlaying(notifier.pathOf(r)),
                        onPlay: () => ref
                            .read(playbackProvider.notifier)
                            .toggle(notifier.pathOf(r)),
                        onMore: () => showRecordingActions(context, ref, r),
                      ),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}
