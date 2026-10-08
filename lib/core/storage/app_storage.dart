import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Folders the app writes to. Everything stays on the device (spec §69).
///
/// * `docs/voice_changer/library/` saved recordings (+ their originals)
/// * `docs/voice_changer/work/` current, not-yet-saved takes and results
/// * `docs/voice_changer/library.json` the History index
class AppStorage {
  AppStorage(this.root);

  final Directory root;

  Directory get library => Directory('${root.path}/library');
  Directory get work => Directory('${root.path}/work');
  File get index => File('${root.path}/library.json');

  String libraryPath(String fileName) => '${library.path}/$fileName';
  String workPath(String fileName) => '${work.path}/$fileName';

  static Future<AppStorage> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final s = AppStorage(Directory('${docs.path}/voice_changer'));
    await s.library.create(recursive: true);
    // Unsaved work from a previous session (e.g. app closed mid-conversion)
    // is cleared on launch so nothing is ever left "stuck".
    if (await s.work.exists()) {
      try {
        await s.work.delete(recursive: true);
      } catch (_) {}
    }
    await s.work.create(recursive: true);
    return s;
  }
}

final appStorageProvider = Provider<AppStorage>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

/// True for "no space left on device" errors (Linux errno 28).
bool isOutOfSpace(Object e) =>
    e is FileSystemException && (e.osError?.errorCode == 28);
