import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/motion/entrance.dart';
import '../../core/motion/motion.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_top_bar.dart';

/// Figma "11 · Settings" (15:1174): Appearance (System / Light / Dark) and
/// About (privacy note, app version).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final mode = ref.watch(themeModeProvider);
    void set(ThemeMode m) {
      HapticFeedback.selectionClick();
      ref.read(themeModeProvider.notifier).set(m);
    }

    Widget divider() => Container(height: 1, color: c.border);

    return Scaffold(
      appBar: const AppTopBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Entrance(
            child: _Group(
              title: 'Appearance',
              children: [
                _RadioRow(
                  label: 'System default',
                  supporting: 'Follows your device setting',
                  selected: mode == ThemeMode.system,
                  onTap: () => set(ThemeMode.system),
                ),
                divider(),
                _RadioRow(
                  label: 'Light',
                  selected: mode == ThemeMode.light,
                  onTap: () => set(ThemeMode.light),
                ),
                divider(),
                _RadioRow(
                  label: 'Dark',
                  selected: mode == ThemeMode.dark,
                  onTap: () => set(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Entrance(
            delay: const Duration(milliseconds: 70),
            child: _Group(
              title: 'About',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.lock, size: 22, color: c.textPrimary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your recordings',
                                style: AppText.body.copyWith(color: c.textPrimary)),
                            const SizedBox(height: 2),
                            Text(
                              'Stored on this device unless you choose to '
                              'export or share them.',
                              style: AppText.caption.copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, size: 22, color: c.textPrimary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text('App version',
                            style: AppText.body.copyWith(color: c.textPrimary)),
                      ),
                      Text(appVersion,
                          style: AppText.body.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppText.label.copyWith(color: c.textSecondary)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Figma "Radio list item": whole row is the touch target.
class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.supporting,
  });

  final String label;
  final String? supporting;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = context.reduceMotion ? Duration.zero : AppMotion.fast;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppText.body.copyWith(color: c.textPrimary)),
                      if (supporting != null) ...[
                        const SizedBox(height: 2),
                        Text(supporting!,
                            style: AppText.caption.copyWith(color: c.textSecondary)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                AnimatedContainer(
                  duration: d,
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? c.primary : c.textSecondary,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: d,
                    curve: AppMotion.settle,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: c.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
