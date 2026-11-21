import 'dart:typed_data';

import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/file_store/audio_file_store_stub.dart'
    if (dart.library.io) 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/file_store/audio_file_store_io.dart'
    as impl;

/// File-system operations needed by the audio download feature.
///
/// The implementation is chosen at compile time (conditional import) so that
/// `dart:io` never reaches a Flutter Web build.
abstract class AudioFileStore {
  /// Absolute path of the folder that holds downloaded guides (created if
  /// missing).
  Future<String> ensureAudioFolder();

  Future<bool> exists(String path);

  Future<void> writeBytes({required String path, required Uint8List bytes});
}

/// Returns the store for the current platform.
AudioFileStore createAudioFileStore() => impl.createAudioFileStore();
