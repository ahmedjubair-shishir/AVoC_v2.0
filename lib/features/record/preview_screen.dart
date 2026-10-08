import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/audio/audio_engine.dart';
import '../../core/audio/playback.dart';
import '../../core/motion/entrance.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/audio_player_card.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/icon_badge.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/status_layout.dart';
import '../recordings/take.dart';
import '../voice/voice_selection_screen.dart';
import 'record_screen.dart';

enum TakeIssue { tooShort, noAudio }

/// Figma "03 · Recording Preview" (7:2), "Too short" (7:78),
/// "Discard dialog" (7:103), plus edge cases "Max length reached" (15:5)
/// and "No audio detected" (15:87).
class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({
    super.key,
    required this.take,
    this.issue,
    this.hitMax = false,
  });

  final Take take;
  final TakeIssue? issue;
  final bool hitMax;

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  late final PlaybackController _playback =
      ref.read(playbackProvider.notifier);
  bool _leaving = false;

  @override
  void dispose() {
    Future.microtask(_playback.stop);
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    if (widget.issue != null) return true; // nothing meaningful to lose
    final discard = await showAppDialog<bool>(
      context,
      title: 'Discard this recording?',
      body: 'Your recording will be removed and can’t be recovered.',
      actions: const [
        DialogAction('Keep', false),
        DialogAction('Discard', true, tone: TextButtonTone.destructive),
      ],
    );
    return discard == true;
  }

  Future<void> _discardAndLeave() async {
    if (!await _confirmDiscard() || !mounted) return;
    _leaving = true;
    await _playback.stop();
    await AudioEngine.deleteQuietly(widget.take.path);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _recordAgain() async {
    if (!await _confirmDiscard() || !mounted) return;
    _leaving = true;
    await _playback.stop();
    await AudioEngine.deleteQuietly(widget.take.path);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RecordScreen()),
    );
  }

  void _continue() {
    _playback.stop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VoiceSelectionScreen(take: widget.take),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final issue = widget.issue;

    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _discardAndLeave();
      },
      child: Scaffold(
        appBar: AppTopBar(title: 'Preview', onNav: _discardAndLeave),
        body: switch (issue) {
          TakeIssue.tooShort => StatusBody(
              badge: IconBadge(
                large: true,
                icon: LucideIcons.timer,
                iconColor: c.textSecondary,
              ),
              title: 'Recording is too short',
              body: 'Record at least 3 seconds so the new voice has enough '
                  'to work with.',
            ),
          TakeIssue.noAudio => StatusBody(
              badge: IconBadge(
                large: true,
                icon: LucideIcons.micOff,
                iconColor: c.textSecondary,
              ),
              title: 'We couldn’t detect enough audio',
              body: 'Make sure your microphone isn’t covered and speak a '
                  'little closer, then try again.',
            ),
          null => ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Entrance(
                  child: Text('Your recording',
                      style: AppText.headline.copyWith(color: c.textPrimary)),
                ),
                const SizedBox(height: 8),
                Entrance(
                  delay: const Duration(milliseconds: 50),
                  child: Text('Listen back before choosing a voice.',
                      style: AppText.body.copyWith(color: c.textSecondary)),
                ),
                if (widget.hitMax) ...[
                  const SizedBox(height: 8),
                  const Entrance(
                    delay: Duration(milliseconds: 80),
                    child: InfoBanner(
                      icon: LucideIcons.timer,
                      text: 'Maximum recording length reached. '
                          'We stopped at 3:00.',
                    ),
                  ),
                ],
                const SizedBox(height: 8 + 16 + 8),
                Entrance(
                  delay: const Duration(milliseconds: 110),
                  child: AudioPlayerCard(
                    path: widget.take.path,
                    title: widget.take.name,
                    duration: widget.take.duration,
                    waveform: widget.take.waveform,
                    showDurationInHeader: true,
                  ),
                ),
              ],
            ),
        },
        bottomNavigationBar: ActionsFooter(
          gap: 12,
          children: issue != null
              ? [PrimaryButton(label: 'Record Again', onPressed: _recordAgain)]
              : [
                  PrimaryButton(label: 'Continue', onPressed: _continue),
                  SecondaryButton(
                    label: 'Record Again',
                    icon: LucideIcons.rotateCcw,
                    onPressed: _recordAgain,
                  ),
                ],
        ),
      ),
    );
  }
}
