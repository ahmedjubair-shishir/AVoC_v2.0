import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/motion/entrance.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/audio/playback.dart';
import '../record/record_flow.dart';
import '../recordings/format.dart';
import '../recordings/recording.dart';
import '../recordings/recording_actions.dart';
import '../recordings/recordings_provider.dart';
import '../recordings/widgets/recording_item.dart';
import '../settings/settings_screen.dart';
import 'widgets/add_new_card.dart';
import 'widgets/recent_empty_state.dart';

/// Home (Figma section "01 · Home"): headline, Add New, and the 3 latest recordings.
///
/// Motion: sections reveal in a short stagger after the splash; the Recent
/// area cross-fades and resizes when switching between list and empty state.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onSeeAll});

  final VoidCallback onSeeAll;

  // Stagger steps for the entrance reveal (must be compile-time constants).
  static const _step = Duration(milliseconds: 70);
  static const _step2 = Duration(milliseconds: 140);
  static const _step3 = Duration(milliseconds: 210);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final recent = ref.watch(recentRecordingsProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: AppSpace.s16,
        title: Text(
          'Voice Changer',
          style: AppText.title.copyWith(color: c.textPrimary),
        ),
        actions: [
          _SettingsButton(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: AppSpace.s4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s16, AppSpace.s8, AppSpace.s16, AppSpace.s16,
        ),
        children: [
          Entrance(
            child: Text(
              'Turn your voice into\nsomething new.',
              style: AppText.headline.copyWith(color: c.textPrimary),
            ),
          ),
          const SizedBox(height: AppSpace.s24),
          Entrance(
            delay: _step,
            child: AddNewCard(onTap: () => startRecordingFlow(context)),
          ),
          const SizedBox(height: AppSpace.s24),
          Entrance(
            delay: _step2,
            child: _RecentHeader(
              showSeeAll: recent.isNotEmpty,
              onSeeAll: onSeeAll,
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          AnimatedSize(
            duration: context.reduceMotion ? Duration.zero : AppMotion.medium,
            curve: AppMotion.enter,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: context.reduceMotion ? Duration.zero : AppMotion.medium,
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exit,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              child: recent.isEmpty
                  ? const Entrance(
                      key: ValueKey('empty'),
                      delay: _step3,
                      child: RecentEmptyState(),
                    )
                  : _RecentList(
                      key: const ValueKey('list'),
                      items: recent,
                      firstDelay: _step3,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentHeader extends StatelessWidget {
  const _RecentHeader({
    required this.showSeeAll,
    required this.onSeeAll,
  });

  final bool showSeeAll;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Recent',
              style: AppText.title.copyWith(color: c.textPrimary),
            ),
          ),
          AnimatedOpacity(
            opacity: showSeeAll ? 1 : 0,
            duration: AppMotion.fast,
            child: IgnorePointer(
              ignoring: !showSeeAll,
              child: Pressable(
                scale: 0.94,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onSeeAll();
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpace.s16),
                    foregroundColor: c.primaryStrong,
                    shape: const StadiumBorder(),
                  ),
                  child: Text('See all', style: AppText.bodyStrong),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentList extends ConsumerWidget {
  const _RecentList({
    super.key,
    required this.items,
    required this.firstDelay,
  });

  final List<Recording> items;
  final Duration firstDelay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pb = ref.watch(playbackProvider);
    final notifier = ref.read(recordingsProvider.notifier);
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s8),
            child: Entrance(
              key: ValueKey(items[i].id),
              delay: firstDelay + const Duration(milliseconds: 50) * i,
              child: RecordingItem(
                recording: items[i],
                whenLabel: formatRelativeDate(items[i].createdAt),
                playing: pb.isPlaying(notifier.pathOf(items[i])),
                onPlay: () => ref
                    .read(playbackProvider.notifier)
                    .toggle(notifier.pathOf(items[i])),
                onMore: () => showRecordingActions(context, ref, items[i]),
              ),
            ),
          ),
      ],
    );
  }
}

/// Settings gear that turns a little on each tap.
class _SettingsButton extends StatefulWidget {
  const _SettingsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<_SettingsButton> {
  double _turns = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      scale: 0.88,
      child: IconButton(
        tooltip: 'Settings',
        onPressed: () {
          HapticFeedback.selectionClick();
          if (!context.reduceMotion) setState(() => _turns += 0.25);
          widget.onTap();
        },
        icon: AnimatedRotation(
          turns: _turns,
          duration: AppMotion.slow,
          curve: AppMotion.settle,
          child: Icon(LucideIcons.settings, color: c.textPrimary),
        ),
      ),
    );
  }
}
