import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_engine.dart';
import '../../core/audio/playback.dart';
import '../../core/motion/entrance.dart';
import '../../core/motion/motion.dart';
import '../../core/storage/app_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/overlays.dart';
import '../convert/converting_screen.dart';
import '../recordings/take.dart';
import '../recordings/voice_style.dart';
import 'category_chips.dart';
import 'voice_card.dart';

/// Figma "04 · Voice Selection" (8:2 default, 8:139 selected + previewing).
///
/// * 2-column grid of 8 voices; tap to select, Apply Voice is disabled until
///   a voice is selected (spec §18).
/// * Preview plays the first seconds of *your own* recording in that voice,
///   one preview at a time (spec §17).
class VoiceSelectionScreen extends ConsumerStatefulWidget {
  const VoiceSelectionScreen({super.key, required this.take, this.initial});

  final Take take;
  final VoiceStyle? initial;

  @override
  ConsumerState<VoiceSelectionScreen> createState() =>
      _VoiceSelectionScreenState();
}

class _VoiceSelectionScreenState extends ConsumerState<VoiceSelectionScreen> {
  static const _previewSeconds = 12.0;

  late final PlaybackController _playback =
      ref.read(playbackProvider.notifier);
  late VoiceStyle? _selected = widget.initial;
  VoiceCategory? _filter; // null = All

  static final Map<VoiceCategory?, int> _counts = {
    null: VoiceStyle.values.length,
    for (final cat in VoiceCategory.values)
      cat: VoiceStyle.values.where((v) => v.category == cat).length,
  };
  final Map<VoiceStyle, String> _previews = {};
  final Set<VoiceStyle> _preparing = {};

  @override
  void dispose() {
    Future.microtask(_playback.stop);
    for (final p in _previews.values) {
      AudioEngine.deleteQuietly(p);
    }
    super.dispose();
  }

  Future<void> _preview(VoiceStyle v) async {
    final existing = _previews[v];
    if (existing != null) {
      await _playback.toggle(existing);
      return;
    }
    if (_preparing.contains(v)) return;
    await _playback.stop();
    setState(() => _preparing.add(v));
    final out = ref
        .read(appStorageProvider)
        .workPath('preview_${widget.take.id}_${v.name}.wav');
    try {
      await AudioEngine.convert(
        inputPath: widget.take.path,
        outputPath: out,
        voice: v,
        maxSeconds: _previewSeconds,
      );
      if (!mounted) return;
      _previews[v] = out;
      setState(() => _preparing.remove(v));
      // Only start if the user hasn't started another preview meanwhile.
      if (_preparing.isEmpty) await _playback.toggle(out);
    } catch (_) {
      if (!mounted) return;
      setState(() => _preparing.remove(v));
      showErrorSnack(context, 'Couldn’t play this preview.');
    }
  }

  void _apply() {
    final v = _selected;
    if (v == null) return;
    _playback.stop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConvertingScreen(take: widget.take, voice: v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pb = ref.watch(playbackProvider);
    final d = context.reduceMotion ? Duration.zero : AppMotion.fast;

    return Scaffold(
      appBar: const AppTopBar(title: 'Choose a voice'),
      body: LayoutBuilder(
        builder: (context, box) {
          final cardW = (box.maxWidth - 32 - 12) / 2;
          final visible = [
            for (final v in VoiceStyle.values)
              if (_filter == null || v.category == _filter) v,
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Preview a voice before applying it to your recording.',
                  style: AppText.body.copyWith(color: c.textSecondary),
                ),
              ),
              const SizedBox(height: 8),
              CategoryChips(
                selected: _filter,
                counts: _counts,
                onChanged: (cat) => setState(() => _filter = cat),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                key: ValueKey(_filter), // re-run the staggered entrance
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final (i, v) in visible.indexed)
                    SizedBox(
                      width: cardW,
                      child: Entrance(
                        delay: Duration(milliseconds: 30 * (i < 8 ? i : 8)),
                        child: VoiceCard(
                          voice: v,
                          selected: _selected == v,
                          preparing: _preparing.contains(v),
                          previewing:
                              _previews[v] != null && pb.isPlaying(_previews[v]!),
                          progress: _previews[v] == null
                              ? 0
                              : pb.progressOf(_previews[v]!),
                          onSelect: () => setState(() => _selected = v),
                          onPreview: () => _preview(v),
                        ),
                      ),
                    ),
                ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: d,
                  child: Text(
                    _selected == null
                        ? 'Select a voice to continue'
                        : '${_selected!.label} selected',
                    key: ValueKey(_selected),
                    style: AppText.label.copyWith(color: c.textSecondary),
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Apply Voice',
                  onPressed: _selected == null ? null : _apply,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
