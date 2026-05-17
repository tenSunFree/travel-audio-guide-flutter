import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide_page.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/repositories/audio_guide_repository.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/usecases/download_audio_guide_usecase.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/usecases/get_audio_guides_usecase.dart';

class MockAudioGuideRepository extends Mock implements AudioGuideRepository {}

void main() {
  late MockAudioGuideRepository repository;

  // setUpAll: mocktail needs registerFallbackValue so that any() can match the AudioGuide type.
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
  });

  setUp(() {
    repository = MockAudioGuideRepository();
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

  const tPage = AudioGuidePage(
    total: 1,
    page: 1,
    hasMore: false,
    items: [tGuide],
  );

  group('GetAudioGuidesUseCase', () {
    late GetAudioGuidesUseCase useCase;

    setUp(() => useCase = GetAudioGuidesUseCase(repository));

    test('呼叫 repository.getAudioGuides 並回傳 AudioGuidePage', () async {
      when(
        () => repository.getAudioGuides(lang: 'zh-tw', page: 1),
      ).thenAnswer((_) async => tPage);

      final result = await useCase(lang: 'zh-tw', page: 1);

      expect(result, tPage);
      expect(result.total, 1);
      expect(result.items.first.title, '故宮導覽');
      expect(result.hasMore, isFalse);

      verify(() => repository.getAudioGuides(lang: 'zh-tw', page: 1)).called(1);

      verifyNoMoreInteractions(repository);
    });

    test('hasMore = true 時正確回傳', () async {
      const pageWithMore = AudioGuidePage(
        total: 100,
        page: 1,
        hasMore: true,
        items: [tGuide],
      );

      when(
        () => repository.getAudioGuides(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
        ),
      ).thenAnswer((_) async => pageWithMore);

      final result = await useCase(lang: 'zh-tw', page: 1);

      expect(result.hasMore, isTrue);
      expect(result.total, 100);
    });

    test('items 為空時正確回傳', () async {
      const emptyPage = AudioGuidePage(
        total: 0,
        page: 1,
        hasMore: false,
        items: [],
      );

      when(
        () => repository.getAudioGuides(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
        ),
      ).thenAnswer((_) async => emptyPage);

      final result = await useCase(lang: 'zh-tw', page: 1);

      expect(result.items, isEmpty);
    });

    test('repository 拋出例外時，useCase 同樣拋出', () {
      when(
        () => repository.getAudioGuides(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
        ),
      ).thenThrow(Exception('server error'));

      expect(() => useCase(lang: 'zh-tw', page: 1), throwsA(isA<Exception>()));
    });
  });

  group('DownloadAudioGuideUseCase', () {
    late DownloadAudioGuideUseCase useCase;

    setUp(() => useCase = DownloadAudioGuideUseCase(repository));

    test('呼叫 repository.downloadAudioGuide 並回傳本地檔案路徑', () async {
      when(
        () => repository.downloadAudioGuide(any()),
      ).thenAnswer((_) async => '/audio/1_故宮導覽.mp3');

      final result = await useCase(tGuide);

      expect(result, '/audio/1_故宮導覽.mp3');

      verify(() => repository.downloadAudioGuide(tGuide)).called(1);

      verifyNoMoreInteractions(repository);
    });

    test('下載失敗時，useCase 拋出例外', () {
      when(
        () => repository.downloadAudioGuide(any()),
      ).thenThrow(Exception('download failed'));

      expect(() => useCase(tGuide), throwsA(isA<Exception>()));
    });
  });
}
