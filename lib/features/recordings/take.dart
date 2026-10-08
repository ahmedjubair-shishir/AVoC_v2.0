import 'package:flutter/foundation.dart';

/// An original recording that is being worked on (not necessarily saved).
/// The same take can be converted many times ("Try Another Voice").
@immutable
class Take {
  const Take({
    required this.id,
    required this.path,
    required this.name,
    required this.duration,
    required this.waveform,
    this.inLibrary = false,
    this.libraryFileName,
  });

  final String id;

  /// WAV file of the original voice.
  final String path;

  /// "Voice Recording 01" or the name the user gave it.
  final String name;
  final Duration duration;
  final List<double> waveform;

  /// True when this original already lives in the library folder
  /// (it came from History), so saving must not copy it again.
  final bool inLibrary;
  final String? libraryFileName;

  Take copyWith({String? name}) => Take(
        id: id,
        path: path,
        name: name ?? this.name,
        duration: duration,
        waveform: waveform,
        inLibrary: inLibrary,
        libraryFileName: libraryFileName,
      );
}
