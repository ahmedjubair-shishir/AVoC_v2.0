import 'dart:io';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/storage/app_storage.dart';
import 'format.dart';

/// File format used for export and sharing.
///
/// NOTE: the Figma file shows MP3, but Android has no built-in MP3 encoder.
/// WAV is used until an encoder is added; only this file needs to change.
abstract final class ExportFormat {
  static const label = 'WAV';
  static const extension = 'wav';
  static const mime = 'audio/wav';
}

/// Exporting, sharing and opening audio files through Android system UI.
abstract final class FileActions {
  /// Copies [sourcePath] to a temp file named `name.wav` so the share sheet
  /// and the save dialog show a friendly file name.
  static Future<String> _namedCopy(
      AppStorage storage, String sourcePath, String name) async {
    final dir = Directory('${storage.work.path}/out');
    await dir.create(recursive: true);
    final path = '${dir.path}/${safeFileName(name)}.${ExportFormat.extension}';
    await File(sourcePath).copy(path);
    return path;
  }

  static String fileNameFor(String name) =>
      '${safeFileName(name)}.${ExportFormat.extension}';

  /// Opens Android's "save to…" picker so the user chooses the folder
  /// (spec §29). Returns null if the user backed out.
  static Future<String?> export(
      AppStorage storage, String sourcePath, String name) async {
    final copy = await _namedCopy(storage, sourcePath, name);
    return FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        sourceFilePath: copy,
        fileName: fileNameFor(name),
      ),
    );
  }

  /// Android system share sheet (spec §30).
  static Future<void> share(
      AppStorage storage, String sourcePath, String name) async {
    final copy = await _namedCopy(storage, sourcePath, name);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(copy, mimeType: ExportFormat.mime)],
        subject: name,
      ),
    );
  }

  /// Opens the file in another app (music player, file manager…).
  static Future<bool> open(String path) async {
    final r = await OpenFilex.open(path, type: ExportFormat.mime);
    return r.type == ResultType.done;
  }
}
