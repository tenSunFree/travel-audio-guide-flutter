import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/file_store/audio_file_store.dart'
    show AudioFileStore;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

AudioFileStore createAudioFileStore() => const _IoAudioFileStore();

class _IoAudioFileStore implements AudioFileStore {
  const _IoAudioFileStore();

  @override
  Future<String> ensureAudioFolder() async {
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(directory.path, 'audio_guides'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder.path;
  }

  @override
  Future<bool> exists(String path) => File(path).exists();

  @override
  Future<void> writeBytes({
    required String path,
    required Uint8List bytes,
  }) async {
    await File(path).writeAsBytes(bytes, flush: true);
  }
}
