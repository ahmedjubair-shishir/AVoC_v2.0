import 'package:flutter/material.dart';

import '../../core/system/mic_permission.dart';
import 'permission_screen.dart';
import 'record_screen.dart';

/// Entry point for "Add New" (spec §8–9):
/// mic already allowed → Recording screen; otherwise explain first.
Future<void> startRecordingFlow(BuildContext context) async {
  final granted = await MicPermission.isGranted();
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          granted ? const RecordScreen() : const PermissionScreen(),
    ),
  );
}
