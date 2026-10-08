import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/audio/playback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/audio_player_card.dart';
import '../../core/widgets/icon_badge.dart';
import '../../core/widgets/status_layout.dart';
import '../recordings/format.dart';
import '../recordings/take.dart';
import '../recordings/voice_style.dart';
import 'converting_screen.dart';

/// Figma "05 · Conversion — Failed" (9:40). The original is kept and can be
/// played; the user can retry or pick another voice (spec §20).
class ConversionFailedScreen extends ConsumerStatefulWidget {
  const ConversionFailedScreen({
    super.key,
    required this.take,
    required this.voice,
    this.outOfSpace = false,
  });

  final Take take;
  final VoiceStyle voice;
  final bool outOfSpace;

  @override
  ConsumerState<ConversionFailedScreen> createState() =>
      _ConversionFailedScreenState();
}

class _ConversionFailedScreenState
    extends ConsumerState<ConversionFailedScreen> {
  late final PlaybackController _playback =
      ref.read(playbackProvider.notifier);

  @override
  void dispose() {
    Future.microtask(_playback.stop);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pb = ref.watch(playbackProvider);
    final playing = pb.isPlaying(widget.take.path);
    return Scaffold(
      appBar: const AppTopBar(title: 'Conversion'),
      body: StatusBody(
        gap: 12,
        badge: IconBadge(
          large: true,
          icon: LucideIcons.circleAlert,
          iconColor: c.error,
        ),
        title: widget.outOfSpace
            ? 'Not enough storage'
            : 'We couldn’t create the voice',
        body: widget.outOfSpace
            ? 'There’s not enough storage to create this voice. Free up some '
                'space on your device, then try again.'
            : 'Something went wrong while processing your recording. '
                'Your original recording is still available.',
        extra: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              PlayPauseButton(
                playing: playing,
                label: playing ? 'Pause original recording' : 'Play original recording',
                onTap: () => _playback.toggle(widget.take.path),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.take.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppText.bodyStrong.copyWith(color: c.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Original · ${formatDuration(widget.take.duration)}',
                        style:
                            AppText.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ActionsFooter(
        gap: 12,
        children: [
          PrimaryButton(
            label: 'Try Again',
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) =>
                    ConvertingScreen(take: widget.take, voice: widget.voice),
              ),
            ),
          ),
          SecondaryButton(
            label: 'Choose Another Voice',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
