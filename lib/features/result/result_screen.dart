import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/audio/audio_engine.dart';
import '../../core/audio/playback.dart';
import '../../core/motion/entrance.dart';
import '../../core/storage/app_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/audio_player_card.dart';
import '../../core/widgets/overlays.dart';
import '../recordings/file_actions.dart';
import '../recordings/format.dart';
import '../recordings/name_sheet.dart';
import '../recordings/recording.dart';
import '../recordings/recordings_provider.dart';
import '../recordings/take.dart';
import '../recordings/voice_style.dart';
import 'saved_screen.dart';

/// Figma "06 · Result" (10:2) with Save & Export (11:2, 11:185) and the
/// storage / export edge cases (15:190, 15:347).
///
/// Original and converted players are stacked so the user never has to
/// remember which is which (spec §24). Back returns to voice selection
/// without deleting the original (prototype notes).
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    super.key,
    required this.take,
    required this.voice,
    required this.convertedPath,
    required this.convertedWaveform,
    required this.convertedDuration,
  });

  final Take take;
  final VoiceStyle voice;
  final String convertedPath;
  final List<double> convertedWaveform;
  final Duration convertedDuration;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late final PlaybackController _playback =
      ref.read(playbackProvider.notifier);
  late final AppStorage _storage = ref.read(appStorageProvider);
  late String _name = widget.take.name;
  Recording? _saved;
  bool _busy = false;

  String get _saveName => _saved?.name ?? '$_name - ${widget.voice.label}';

  @override
  void initState() {
    super.initState();
    // Celebrate the result: play the new voice right away.
    Future.microtask(() => _playback.toggle(widget.convertedPath));
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    Future.microtask(_playback.stop);
    if (_saved == null) AudioEngine.deleteQuietly(widget.convertedPath);
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    var recording = _saved;
    if (recording == null) {
      final name = await showNameSheet(
        context,
        initial: _saveName,
        voice: widget.voice,
      );
      if (name == null || !mounted) return;
      recording = await _saveToLibrary(name);
      if (recording == null || !mounted) return;
    }
    await _export(recording);
  }

  Future<Recording?> _saveToLibrary(String name) async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(recordingsProvider.notifier).saveResult(
            take: widget.take.copyWith(name: _name),
            voice: widget.voice,
            convertedPath: widget.convertedPath,
            duration: widget.convertedDuration,
            name: name,
          );
      setState(() => _saved = r);
      return r;
    } catch (e) {
      if (!mounted) return null;
      if (isOutOfSpace(e)) {
        final retry = await showAppDialog<bool>(
          context,
          title: 'Not enough storage',
          body: 'There’s not enough storage to save this recording. Free up '
              'some space on your device, then try again.',
          actions: const [
            DialogAction('Cancel', false, tone: TextButtonTone.neutral),
            DialogAction('Try Again', true),
          ],
        );
        if (retry == true && mounted) return _saveToLibrary(name);
      } else {
        showErrorSnack(context, 'Couldn’t save the recording.');
      }
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export(Recording r) async {
    final notifier = ref.read(recordingsProvider.notifier);
    try {
      final savedTo =
          await FileActions.export(_storage, notifier.pathOf(r), r.name);
      if (!mounted) return;
      if (savedTo == null) {
        showAppSnack(context, 'Saved to History.',
            icon: LucideIcons.circleCheck);
        return;
      }
      await _playback.stop();
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => SavedScreen(recording: r)),
      );
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(
        context,
        'Couldn’t save the file.',
        actionLabel: 'Retry',
        onAction: () => _export(r),
      );
    }
  }

  Future<void> _rename() async {
    final name = await showNameSheet(context, initial: _saved?.name ?? _name);
    if (name == null || !mounted) return;
    if (_saved != null) {
      await ref.read(recordingsProvider.notifier).rename(_saved!.id, name);
      setState(() => _saved = _saved!.copyWith(name: name));
    } else {
      setState(() => _name = name);
    }
    if (mounted) showAppSnack(context, 'Recording renamed.');
  }

  Future<void> _share() async {
    try {
      await FileActions.share(_storage, widget.convertedPath, _saveName);
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Couldn’t share the file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = _saved?.name ?? _name;
    return Scaffold(
      appBar: const AppTopBar(title: 'Your result'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          Entrance(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      title,
                      key: ValueKey(title),
                      style: AppText.headline.copyWith(color: c.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.voice.label} voice · '
                    '${formatDuration(widget.convertedDuration)}',
                    style: AppText.body.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Entrance(
            delay: const Duration(milliseconds: 60),
            child: AudioPlayerCard(
              path: widget.take.path,
              title: 'Original',
              duration: widget.take.duration,
              waveform: widget.take.waveform,
            ),
          ),
          const SizedBox(height: 12),
          Entrance(
            delay: const Duration(milliseconds: 120),
            child: AudioPlayerCard(
              path: widget.convertedPath,
              title: widget.voice.label,
              duration: widget.convertedDuration,
              waveform: widget.convertedWaveform,
              voice: widget.voice,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                label: _saved == null ? 'Save' : 'Export',
                icon: LucideIcons.download,
                loading: _busy,
                onPressed: _save,
              ),
              const SizedBox(height: 8),
              SecondaryButton(
                label: 'Try Another Voice',
                icon: LucideIcons.rotateCcw,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AppTextButton(
                      label: 'Share',
                      icon: LucideIcons.share2,
                      expand: true,
                      onPressed: _share,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTextButton(
                      label: 'Rename',
                      icon: LucideIcons.pencil,
                      expand: true,
                      onPressed: _rename,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
