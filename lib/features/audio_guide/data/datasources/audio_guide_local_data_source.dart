import 'dart:typed_data';

import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/file_store/audio_file_store.dart';
import 'package:path/path.dart' as p;

/// Local storage for downloaded audio guides.
///
/// All `dart:io` access lives behind [AudioFileStore] (conditional import),
/// so this class compiles and runs on Flutter Web, where it behaves as an
/// always-empty store.
class AudioGuideLocalDataSource {
  const AudioGuideLocalDataSource();

  Future<String> getAudioFilePath({
    required int id,
    required String title,
  }) async {
    final String folder;
    try {
      folder = await createAudioFileStore().ensureAudioFolder();
    } on LocalStorageException {
      rethrow;
    } catch (e) {
      throw LocalStorageException('建立本地資料夾失敗：$e');
    }
    final filename = _buildFileName(id: id, title: title);
    return p.join(folder, filename);
  }

  Future<bool> existsPath(String path) async {
    try {
      return await createAudioFileStore().exists(path);
    } catch (e) {
      throw LocalStorageException('檢查本地檔案失敗：$e');
    }
  }

  Future<void> writeBytes({
    required Uint8List bytes,
    required String path,
  }) async {
    try {
      await createAudioFileStore().writeBytes(path: path, bytes: bytes);
    } on LocalStorageException {
      rethrow;
    } catch (e) {
      throw LocalStorageException('儲存本地檔案失敗：$e');
    }
  }

  String _buildFileName({required int id, required String title}) {
    final sanitizedTitle = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();

    final safeTitle = sanitizedTitle.isEmpty
        ? 'audio_$id'
        : '${id}_$sanitizedTitle';
    return '$safeTitle.mp3';
  }
}
