import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_engine.dart';
import '../../core/storage/app_storage.dart';
import 'recording.dart';
import 'take.dart';
import 'voice_style.dart';

/// The user's saved recordings, newest first, persisted as JSON on device.
class RecordingsNotifier extends Notifier<List<Recording>> {
  AppStorage get _storage => ref.read(appStorageProvider);

  @override
  List<Recording> build() {
    final file = ref.watch(appStorageProvider).index;
    if (!file.existsSync()) return const [];
    try {
      final raw = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      final list = [
        for (final e in raw)
          ?Recording.fromJson((e as Map).cast<String, Object?>()),
      ]
        // Drop entries whose audio file has gone missing.
        ..removeWhere((r) => !File(_storagePath(r.fileName)).existsSync());
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return const [];
    }
  }

  String _storagePath(String name) =>
      ref.read(appStorageProvider).libraryPath(name);

  String pathOf(Recording r) => _storage.libraryPath(r.fileName);
  String sourcePathOf(Recording r) => _storage.libraryPath(r.sourceFileName);

  Future<void> _persist() async {
    final tmp = File('${_storage.index.path}.tmp');
    await tmp.writeAsString(jsonEncode([for (final r in state) r.toJson()]),
        flush: true);
    await tmp.rename(_storage.index.path);
  }

  Future<void> add(Recording r) async {
    state = [r, ...state];
    await _persist();
  }

  /// Copies a converted result (and its original, once) into the library
  /// and adds it to History. Throws on storage errors (e.g. disk full).
  Future<Recording> saveResult({
    required Take take,
    required VoiceStyle voice,
    required String convertedPath,
    required Duration duration,
    required String name,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final fileName = 'rec_$id.wav';
    final sourceFileName = take.libraryFileName ?? 'orig_${take.id}.wav';

    if (!take.inLibrary) {
      final dest = File(_storage.libraryPath(sourceFileName));
      if (!await dest.exists()) await File(take.path).copy(dest.path);
    }
    await File(convertedPath).copy(_storage.libraryPath(fileName));

    final r = Recording(
      id: id,
      name: name,
      voice: voice,
      duration: duration,
      createdAt: DateTime.now(),
      fileName: fileName,
      sourceFileName: sourceFileName,
      sourceName: take.name,
    );
    await add(r);
    return r;
  }

  Future<void> rename(String id, String name) async {
    state = [for (final r in state) r.id == id ? r.copyWith(name: name) : r];
    await _persist();
  }

  /// Removes the recording and its files. The original is kept while other
  /// saved results still use it.
  Future<Recording?> delete(String id) async {
    final target = state.where((r) => r.id == id).firstOrNull;
    if (target == null) return null;
    state = state.where((r) => r.id != id).toList();
    await _persist();
    await AudioEngine.deleteQuietly(pathOf(target));
    final sourceStillUsed =
        state.any((r) => r.sourceFileName == target.sourceFileName);
    if (!sourceStillUsed) {
      await AudioEngine.deleteQuietly(sourcePathOf(target));
    }
    return target;
  }
}

final recordingsProvider =
    NotifierProvider<RecordingsNotifier, List<Recording>>(
  RecordingsNotifier.new,
);

/// Home shows only the latest 3 (spec §7).
final recentRecordingsProvider = Provider<List<Recording>>(
  (ref) => ref.watch(recordingsProvider).take(3).toList(),
);
