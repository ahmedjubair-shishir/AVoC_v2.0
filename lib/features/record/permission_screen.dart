import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/system/mic_permission.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/icon_badge.dart';
import '../../core/widgets/status_layout.dart';
import 'record_screen.dart';

/// Figma "Mic Permission — Explain / Denied" (6:3, 6:29).
///
/// Explain first, then show Android's prompt (never ask without context).
/// If denied: explain how to turn it on in Settings, and re-check when the
/// user comes back to the app.
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  bool _denied = false;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from Android Settings: continue if access was turned on.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _denied) _checkAndContinue();
  }

  Future<void> _checkAndContinue() async {
    if (await MicPermission.isGranted()) _goRecord();
  }

  void _goRecord() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RecordScreen()),
    );
  }

  Future<void> _request() async {
    if (_asking) return;
    setState(() => _asking = true);
    final granted = await MicPermission.request();
    if (!mounted) return;
    setState(() => _asking = false);
    if (granted) {
      _goRecord();
    } else {
      setState(() => _denied = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: const AppTopBar(title: ''),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _denied
            ? StatusBody(
                key: const ValueKey('denied'),
                badge: IconBadge(
                  large: true,
                  icon: LucideIcons.micOff,
                  iconColor: c.textSecondary,
                ),
                title: 'Microphone access is off',
                body: 'To record your voice, allow microphone access in your '
                    'device settings.',
              )
            : StatusBody(
                key: const ValueKey('explain'),
                badge: IconBadge(
                  large: true,
                  icon: LucideIcons.mic,
                  background: c.primaryContainer,
                ),
                title: 'Allow microphone access',
                body: 'Microphone access is needed to record your voice. '
                    'Android will ask you to confirm next.',
              ),
      ),
      bottomNavigationBar: ActionsFooter(
        children: _denied
            ? [
                PrimaryButton(
                  label: 'Open Settings',
                  onPressed: MicPermission.openAppSettings,
                ),
                AppTextButton(
                  label: 'Try Again',
                  expand: true,
                  onPressed: _request,
                ),
              ]
            : [
                PrimaryButton(
                  label: 'Continue',
                  loading: _asking,
                  onPressed: _request,
                ),
                AppTextButton(
                  label: 'Not now',
                  expand: true,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
      ),
    );
  }
}
