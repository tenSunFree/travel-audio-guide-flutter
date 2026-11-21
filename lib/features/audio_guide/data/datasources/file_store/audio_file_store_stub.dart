import 'dart:typed_data';

import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/file_store/audio_file_store.dart'
    show AudioFileStore;

/// Used when `dart:io` is unavailable (Flutter Web): there is no local file
/// system, so nothing can be downloaded and nothing ever "exists".
AudioFileStore createAudioFileStore() => const _UnsupportedAudioFileStore();

class _UnsupportedAudioFileStore implements AudioFileStore {
  const _UnsupportedAudioFileStore();

  @override
  Future<String> ensureAudioFolder() async {
    throw const LocalStorageException('此平台不支援本地音訊檔案');
  }

  @override
  Future<bool> exists(String path) async => false;

  @override
  Future<void> writeBytes({
    required String path,
    required Uint8List bytes,
  }) async {
    throw const LocalStorageException('此平台不支援下載音訊檔案');
  }
}
