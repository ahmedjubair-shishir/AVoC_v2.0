import 'package:flutter/foundation.dart';

import 'voice_style.dart';

/// A saved, converted recording shown in Home › Recent and History.
@immutable
class Recording {
  const Recording({
    required this.id,
    required this.name,
    required this.voice,
    required this.duration,
    required this.createdAt,
    required this.fileName,
    required this.sourceFileName,
    required this.sourceName,
  });

  final String id;
  final String name;
  final VoiceStyle voice;
  final Duration duration;
  final DateTime createdAt;

  /// Converted audio, inside the library folder.
  final String fileName;

  /// The original recording it was made from (kept for "Try Another Voice").
  final String sourceFileName;

  /// Name of the original take, e.g. "Morning Recording".
  final String sourceName;

  Recording copyWith({String? name}) => Recording(
        id: id,
        name: name ?? this.name,
        voice: voice,
        duration: duration,
        createdAt: createdAt,
        fileName: fileName,
        sourceFileName: sourceFileName,
        sourceName: sourceName,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'voice': voice.name,
        'durationMs': duration.inMilliseconds,
        'createdAt': createdAt.toIso8601String(),
        'file': fileName,
        'source': sourceFileName,
        'sourceName': sourceName,
      };

  static Recording? fromJson(Map<String, Object?> j) {
    final voice = VoiceStyle.byName(j['voice'] as String?);
    if (voice == null) return null;
    return Recording(
      id: j['id'] as String,
      name: j['name'] as String,
      voice: voice,
      duration: Duration(milliseconds: (j['durationMs'] as num).toInt()),
      createdAt: DateTime.parse(j['createdAt'] as String),
      fileName: j['file'] as String,
      sourceFileName: j['source'] as String,
      sourceName: (j['sourceName'] as String?) ?? j['name'] as String,
    );
  }
}
