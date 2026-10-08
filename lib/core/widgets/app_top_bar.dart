import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_buttons.dart';

enum TopBarNav { none, back, close }

/// Figma "Top app bar" (64dp). Small = Title style; large = Headline style
/// for top-level destinations (History).
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.nav = TopBarNav.back,
    this.onNav,
    this.large = false,
    this.actions = const [],
  });

  final String title;
  final TopBarNav nav;

  /// Defaults to Navigator.maybePop (which respects PopScope guards).
  final VoidCallback? onNav;
  final bool large;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasNav = nav != TopBarNav.none;
    return AppBar(
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      titleSpacing: hasNav ? 0 : 16,
      leading: hasNav
          ? Padding(
              padding: const EdgeInsets.only(left: 4),
              child: AppIconButton(
                icon: nav == TopBarNav.close
                    ? LucideIcons.x
                    : LucideIcons.arrowLeft,
                tooltip: nav == TopBarNav.close ? 'Close' : 'Back',
                onPressed: onNav ?? () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      title: Text(
        title,
        style: (large ? AppText.headline : AppText.title)
            .copyWith(color: c.textPrimary),
      ),
      actions: [...actions, if (actions.isNotEmpty) const SizedBox(width: 4)],
    );
  }
}
