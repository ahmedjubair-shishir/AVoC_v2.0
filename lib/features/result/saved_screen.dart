import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/storage/app_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/icon_badge.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/status_layout.dart';
import '../recordings/file_actions.dart';
import '../recordings/format.dart';
import '../recordings/recording.dart';
import '../recordings/recordings_provider.dart';

/// Figma "07 · Saved — Success" (11:356). Done returns to Home.
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key, required this.recording});

  final Recording recording;

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  void _done() => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = widget.recording;
    final path = ref.read(recordingsProvider.notifier).pathOf(r);
    final storage = ref.read(appStorageProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _done();
      },
      child: Scaffold(
        body: SafeArea(
          child: StatusBody(
            gap: 12,
            badge: _SuccessBadge(color: c.success),
            title: 'Saved successfully',
            body: 'Your file is saved to the folder you chose.',
            extra: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(LucideIcons.music, size: 20, color: c.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(FileActions.fileNameFor(r.name),
                            style: AppText.bodyStrong
                                .copyWith(color: c.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          '${ExportFormat.label} · ${formatDuration(r.duration)}',
                          style:
                              AppText.caption.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: ActionsFooter(
          gap: 12,
          children: [
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Share',
                    icon: LucideIcons.share2,
                    onPressed: () => FileActions.share(storage, path, r.name),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SecondaryButton(
                    label: 'Open File',
                    icon: LucideIcons.folderOpen,
                    onPressed: () async {
                      final ok = await FileActions.open(path);
                      if (!ok && context.mounted) {
                        showErrorSnack(
                            context, 'No app found to open this file.');
                      }
                    },
                  ),
                ),
              ],
            ),
            PrimaryButton(label: 'Done', onPressed: _done),
          ],
        ),
      ),
    );
  }
}

/// Success badge with a check that draws itself in.
class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: IconBadge(large: true, icon: LucideIcons.check, iconColor: color),
    );
  }
}
