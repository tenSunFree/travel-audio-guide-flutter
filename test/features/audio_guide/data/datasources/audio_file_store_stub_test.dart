import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/file_store/audio_file_store_stub.dart';

/// The stub is what Flutter Web compiles in place of the dart:io store.
void main() {
  final store = createAudioFileStore();

  test('exists 一律回傳 false', () async {
    expect(await store.exists('/any/path.mp3'), isFalse);
  });

  test('ensureAudioFolder 與 writeBytes 拋出 LocalStorageException', () async {
    await expectLater(
      store.ensureAudioFolder(),
      throwsA(isA<LocalStorageException>()),
    );
    await expectLater(
      store.writeBytes(path: '/x.mp3', bytes: Uint8List(1)),
      throwsA(isA<LocalStorageException>()),
    );
  });
}
