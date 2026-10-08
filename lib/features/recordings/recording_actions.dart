import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/audio/audio_engine.dart';
import '../../core/audio/playback.dart';
import '../../core/storage/app_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/overlays.dart';
import '../voice/voice_selection_screen.dart';
import 'file_actions.dart';
import 'format.dart';
import 'name_sheet.dart';
import 'recording.dart';
import 'recordings_provider.dart';
import 'take.dart';

enum _Action { play, rename, another, export, share, delete }

/// Figma "BottomSheet/Item actions" (13:183) and everything behind it:
/// Play, Rename, Try Another Voice, Export, Share, Delete (spec §32–35).
Future<void> showRecordingActions(
  BuildContext context,
  WidgetRef ref,
  Recording r,
) async {
  final playing = ref.read(playbackProvider).isPlaying(
        ref.read(recordingsProvider.notifier).pathOf(r),
      );
  final action = await showAppSheet<_Action>(
    context,
    builder: (ctx) => _ActionsSheet(recording: r, playing: playing),
  );
  if (action == null || !context.mounted) return;

  final notifier = ref.read(recordingsProvider.notifier);
  final storage = ref.read(appStorageProvider);
  final path = notifier.pathOf(r);

  switch (action) {
    case _Action.play:
      await ref.read(playbackProvider.notifier).toggle(path);
    case _Action.rename:
      final name = await showNameSheet(context, initial: r.name);
      if (name == null || name == r.name) return;
      await notifier.rename(r.id, name);
      if (context.mounted) showAppSnack(context, 'Recording renamed.');
    case _Action.another:
      // Reuse the original; the existing result is never overwritten (§33).
      final sourcePath = notifier.sourcePathOf(r);
      final analysis = await AudioEngine.analyze(sourcePath);
      if (!context.mounted) return;
      await ref.read(playbackProvider.notifier).stop();
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VoiceSelectionScreen(
            take: Take(
              id: 'lib_${r.id}',
              path: sourcePath,
              name: r.sourceName,
              duration: analysis.duration,
              waveform: analysis.waveform,
              inLibrary: true,
              libraryFileName: r.sourceFileName,
            ),
          ),
        ),
      );
    case _Action.export:
      try {
        final saved = await FileActions.export(storage, path, r.name);
        if (saved != null && context.mounted) {
          showAppSnack(context, 'File saved.', icon: LucideIcons.circleCheck);
        }
      } catch (_) {
        if (context.mounted) showErrorSnack(context, 'Couldn’t save the file.');
      }
    case _Action.share:
      await FileActions.share(storage, path, r.name);
    case _Action.delete:
      final ok = await showAppDialog<bool>(
        context,
        title: 'Delete recording?',
        body: '“${r.name}” will be permanently removed from this device. '
            'Files you already exported stay where you saved them.',
        actions: const [
          DialogAction('Cancel', false, tone: TextButtonTone.neutral),
          DialogAction('Delete', true, tone: TextButtonTone.destructive),
        ],
      );
      if (ok != true) return;
      if (ref.read(playbackProvider).path == path) {
        await ref.read(playbackProvider.notifier).stop();
      }
      await notifier.delete(r.id);
      HapticFeedback.mediumImpact();
      if (context.mounted) showAppSnack(context, 'Recording deleted.');
  }
}

class _ActionsSheet extends StatelessWidget {
  const _ActionsSheet({required this.recording, required this.playing});

  final Recording recording;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = recording;
    Widget item(_Action a, IconData icon, String label, {bool danger = false}) {
      final color = danger ? c.error : c.textPrimary;
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).pop(a);
        },
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(label, style: AppText.body.copyWith(color: color)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget divider() => Container(height: 1, color: c.border);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DragHandle(),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title.copyWith(color: c.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    '${r.voice.label} · ${formatDuration(r.duration)} · '
                    '${formatDateTime(r.createdAt)}',
                    style: AppText.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            divider(),
            const SizedBox(height: 4),
            item(_Action.play, playing ? LucideIcons.pause : LucideIcons.play,
                playing ? 'Pause' : 'Play'),
            const SizedBox(height: 4),
            item(_Action.rename, LucideIcons.pencil, 'Rename'),
            const SizedBox(height: 4),
            item(_Action.another, LucideIcons.rotateCcw, 'Try Another Voice'),
            const SizedBox(height: 4),
            item(_Action.export, LucideIcons.download, 'Export'),
            const SizedBox(height: 4),
            item(_Action.share, LucideIcons.share2, 'Share'),
            const SizedBox(height: 4),
            divider(),
            const SizedBox(height: 4),
            item(_Action.delete, LucideIcons.trash2, 'Delete', danger: true),
          ],
        ),
      ),
    );
  }
}
