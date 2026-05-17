import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/audio_guide_local_data_source.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/audio_guide_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/models/audio_guide_model.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/models/audio_guide_page_model.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/repositories/audio_guide_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';

class MockAudioGuideRemoteDataSource extends Mock
    implements AudioGuideRemoteDataSource {}

class MockAudioGuideLocalDataSource extends Mock
    implements AudioGuideLocalDataSource {}

void main() {
  late MockAudioGuideRemoteDataSource remoteDataSource;
  late MockAudioGuideLocalDataSource localDataSource;
  late AudioGuideRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const AudioGuide(
        id: 0,
        title: 'fallback',
        url: '',
        modified: '',
        isDownloaded: false,
      ),
    );
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    remoteDataSource = MockAudioGuideRemoteDataSource();
    localDataSource = MockAudioGuideLocalDataSource();

    // If the mocktail method doesn't have a stub, it defaults to returning null.
    // `writeBytes` returns a `Future<void>`, and null is not a valid value.
    // This will throw a `_TypeError: Null is not a subtype of Future<void>` at runtime.
    // This will cause the test to crash before the expected `DownloadException` is thrown.
    // Add a default stub to `setUp` to ensure all tests are safe.
    when(
      () => localDataSource.writeBytes(
        bytes: any(named: 'bytes'),
        path: any(named: 'path'),
      ),
    ).thenAnswer((_) async {});

    repository = AudioGuideRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );
  });

  const tGuide = AudioGuide(
    id: 1,
    title: '故宮導覽',
    summary: '語音導覽',
    url: 'https://example.com/1.mp3',
    fileExt: 'mp3',
    modified: '2026-05-01',
    isDownloaded: false,
    localFilePath: null,
  );

  const tModel1 = AudioGuideModel(
    id: 1,
    title: '故宮導覽',
    summary: '語音導覽',
    url: 'https://example.com/1.mp3',
    fileExt: 'mp3',
    modified: '2026-05-01',
  );

  const tModel2 = AudioGuideModel(
    id: 2,
    title: '北投導覽',
    summary: '溫泉介紹',
    url: 'https://example.com/2.mp3',
    fileExt: 'mp3',
    modified: '2026-05-02',
  );

  group('AudioGuideRepositoryImpl.getAudioGuides', () {
    test('正確映射 remote model 並根據本地檔案設定 isDownloaded', () async {
      when(
        () => remoteDataSource.getAudioGuides(lang: 'zh-tw', page: 1),
      ).thenAnswer(
        (_) async =>
            AudioGuidePageModel(total: 2, page: 1, data: [tModel1, tModel2]),
      );

      when(
        () => localDataSource.getAudioFilePath(id: 1, title: '故宮導覽'),
      ).thenAnswer((_) async => '/audio/1_故宮導覽.mp3');

      when(
        () => localDataSource.getAudioFilePath(id: 2, title: '北投導覽'),
      ).thenAnswer((_) async => '/audio/2_北投導覽.mp3');

      when(
        () => localDataSource.existsPath('/audio/1_故宮導覽.mp3'),
      ).thenAnswer((_) async => true);

      when(
        () => localDataSource.existsPath('/audio/2_北投導覽.mp3'),
      ).thenAnswer((_) async => false);

      final result = await repository.getAudioGuides(lang: 'zh-tw', page: 1);

      expect(result.total, 2);
      expect(result.page, 1);
      expect(result.items.length, 2);

      expect(result.items[0].isDownloaded, isTrue);
      expect(result.items[0].localFilePath, '/audio/1_故宮導覽.mp3');

      expect(result.items[1].isDownloaded, isFalse);
      expect(result.items[1].localFilePath, isNull);

      verify(
        () => remoteDataSource.getAudioGuides(lang: 'zh-tw', page: 1),
      ).called(1);

      verify(
        () => localDataSource.getAudioFilePath(id: 1, title: '故宮導覽'),
      ).called(1);

      verify(
        () => localDataSource.getAudioFilePath(id: 2, title: '北投導覽'),
      ).called(1);
    });

    test('total=2, page=1 → hasMore = false', () async {
      when(
        () => remoteDataSource.getAudioGuides(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
        ),
      ).thenAnswer(
        (_) async =>
            AudioGuidePageModel(total: 2, page: 1, data: [tModel1, tModel2]),
      );

      when(
        () => localDataSource.getAudioFilePath(
          id: any(named: 'id'),
          title: any(named: 'title'),
        ),
      ).thenAnswer((_) async => '/audio/fake.mp3');

      when(
        () => localDataSource.existsPath(any()),
      ).thenAnswer((_) async => false);

      final result = await repository.getAudioGuides(lang: 'zh-tw', page: 1);

      expect(result.hasMore, isFalse);
    });

    test('total=100, page=1 → hasMore = true', () async {
      when(
        () => remoteDataSource.getAudioGuides(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
        ),
      ).thenAnswer(
        (_) async => AudioGuidePageModel(
          total: 100,
          page: 1,
          data: List.generate(
            30,
            (i) => AudioGuideModel(
              id: i + 1,
              title: 'Guide ${i + 1}',
              url: 'https://example.com/${i + 1}.mp3',
              modified: '2026-01-01',
            ),
          ),
        ),
      );

      when(
        () => localDataSource.getAudioFilePath(
          id: any(named: 'id'),
          title: any(named: 'title'),
        ),
      ).thenAnswer((_) async => '/audio/fake.mp3');

      when(
        () => localDataSource.existsPath(any()),
      ).thenAnswer((_) async => false);

      final result = await repository.getAudioGuides(lang: 'zh-tw', page: 1);

      expect(result.hasMore, isTrue);
    });

    test('空資料時 items 為空且 hasMore = false', () async {
      when(
        () => remoteDataSource.getAudioGuides(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
        ),
      ).thenAnswer(
        (_) async => const AudioGuidePageModel(total: 0, page: 1, data: []),
      );

      final result = await repository.getAudioGuides(lang: 'zh-tw', page: 1);

      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);

      verifyNever(
        () => localDataSource.getAudioFilePath(
          id: any(named: 'id'),
          title: any(named: 'title'),
        ),
      );
    });
  });

  group('AudioGuideRepositoryImpl.downloadAudioGuide', () {
    test('檔案已存在時直接回傳本地路徑，不重新下載', () async {
      when(
        () => localDataSource.getAudioFilePath(id: 1, title: '故宮導覽'),
      ).thenAnswer((_) async => '/audio/1_故宮導覽.mp3');

      when(
        () => localDataSource.existsPath('/audio/1_故宮導覽.mp3'),
      ).thenAnswer((_) async => true);

      final result = await repository.downloadAudioGuide(tGuide);

      expect(result, '/audio/1_故宮導覽.mp3');

      verifyNever(() => remoteDataSource.downloadAudioBinary(any()));

      verifyNever(
        () => localDataSource.writeBytes(
          bytes: any(named: 'bytes'),
          path: any(named: 'path'),
        ),
      );
    });

    test('檔案不存在時，下載並寫入本地，回傳路徑', () async {
      final fakeBytes = Uint8List.fromList([0xFF, 0xFB, 0x90, 0x00]);

      when(
        () => localDataSource.getAudioFilePath(id: 1, title: '故宮導覽'),
      ).thenAnswer((_) async => '/audio/1_故宮導覽.mp3');

      when(
        () => localDataSource.existsPath('/audio/1_故宮導覽.mp3'),
      ).thenAnswer((_) async => false);

      when(
        () => remoteDataSource.downloadAudioBinary('https://example.com/1.mp3'),
      ).thenAnswer(
        (_) async => DownloadedAudioBinary(
          bytes: fakeBytes,
          contentType: 'audio/mpeg',
          finalUrl: 'https://example.com/1.mp3',
        ),
      );

      when(
        () => localDataSource.writeBytes(
          bytes: fakeBytes,
          path: '/audio/1_故宮導覽.mp3',
        ),
      ).thenAnswer((_) async {});

      final result = await repository.downloadAudioGuide(tGuide);

      expect(result, '/audio/1_故宮導覽.mp3');

      verify(
        () => remoteDataSource.downloadAudioBinary('https://example.com/1.mp3'),
      ).called(1);

      verify(
        () => localDataSource.writeBytes(
          bytes: fakeBytes,
          path: '/audio/1_故宮導覽.mp3',
        ),
      ).called(1);
    });

    test(
      'contentType = text/html 且 URL 不含 .mp3 → 拋出 DownloadException',
      () async {
        // guide.url cannot end with .mp3,
        // Otherwise, looksLikeAudio = true, and the repository will not throw a DownloadException.
        // Checks for looksLikeAudio:
        // contentType.contains('audio') → text/html → false
        // finalUrl.endsWith('.mp3') → login.html → false
        // guide.url.endsWith('.mp3') → must also be false here.
        const htmlGuide = AudioGuide(
          id: 1,
          title: '故宮導覽',
          url: 'https://example.com/download?id=1',
          // ← 不含 .mp3
          modified: '2026-05-01',
          isDownloaded: false,
        );

        when(
          () => localDataSource.getAudioFilePath(id: 1, title: '故宮導覽'),
        ).thenAnswer((_) async => '/audio/1_故宮導覽.mp3');

        when(
          () => localDataSource.existsPath('/audio/1_故宮導覽.mp3'),
        ).thenAnswer((_) async => false);

        when(
          () => remoteDataSource.downloadAudioBinary(
            'https://example.com/download?id=1',
          ),
        ).thenAnswer(
          (_) async => DownloadedAudioBinary(
            bytes: Uint8List.fromList([60, 104, 116, 109, 108]), // <html
            contentType: 'text/html',
            finalUrl: 'https://example.com/login.html', // ← 不含 .mp3
          ),
        );

        await expectLater(
          () => repository.downloadAudioGuide(htmlGuide),
          throwsA(isA<DownloadException>()),
        );

        verifyNever(
          () => localDataSource.writeBytes(
            bytes: any(named: 'bytes'),
            path: any(named: 'path'),
          ),
        );
      },
    );

    test(
      'contentType = application/octet-stream 但 finalUrl 結尾 .mp3 → 視為音訊',
      () async {
        when(
          () => localDataSource.getAudioFilePath(id: 1, title: '故宮導覽'),
        ).thenAnswer((_) async => '/audio/1_故宮導覽.mp3');

        when(
          () => localDataSource.existsPath('/audio/1_故宮導覽.mp3'),
        ).thenAnswer((_) async => false);

        when(
          () =>
              remoteDataSource.downloadAudioBinary('https://example.com/1.mp3'),
        ).thenAnswer(
          (_) async => DownloadedAudioBinary(
            bytes: Uint8List.fromList([1, 2, 3]),
            contentType: 'application/octet-stream',
            finalUrl: 'https://cdn.example.com/redirect/1.mp3',
          ),
        );

        when(
          () => localDataSource.writeBytes(
            bytes: any(named: 'bytes'),
            path: any(named: 'path'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.downloadAudioGuide(tGuide);

        expect(result, '/audio/1_故宮導覽.mp3');

        verify(
          () => localDataSource.writeBytes(
            bytes: any(named: 'bytes'),
            path: '/audio/1_故宮導覽.mp3',
          ),
        ).called(1);
      },
    );
  });

  // ── isGuideDownloaded ─────────────────────────────────────────────────────

  group('AudioGuideRepositoryImpl.isGuideDownloaded', () {
    test('本地檔案存在時回傳 true', () async {
      when(
        () => localDataSource.getAudioFilePath(id: 1, title: '故宮導覽'),
      ).thenAnswer((_) async => '/audio/1_故宮導覽.mp3');

      when(
        () => localDataSource.existsPath('/audio/1_故宮導覽.mp3'),
      ).thenAnswer((_) async => true);

      final result = await repository.isGuideDownloaded(tGuide);

      expect(result, isTrue);
    });

    test('本地檔案不存在時回傳 false', () async {
      when(
        () => localDataSource.getAudioFilePath(id: 1, title: '故宮導覽'),
      ).thenAnswer((_) async => '/audio/1_故宮導覽.mp3');

      when(
        () => localDataSource.existsPath('/audio/1_故宮導覽.mp3'),
      ).thenAnswer((_) async => false);

      final result = await repository.isGuideDownloaded(tGuide);

      expect(result, isFalse);
    });
  });
}
