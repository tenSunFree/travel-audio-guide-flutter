import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity_page.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/repositories/activity_repository.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/usecases/get_activities_usecase.dart';

class MockActivityRepository extends Mock implements ActivityRepository {}

void main() {
  late MockActivityRepository repository;
  late GetActivitiesUseCase useCase;

  setUp(() {
    repository = MockActivityRepository();
    useCase = GetActivitiesUseCase(repository);
  });

  const tActivity = Activity(
    id: 1,
    title: '台北活動',
    description: '活動說明',
    begin: '2026-05-01',
    end: '2026-05-31',
    posted: '2026-04-01',
    modified: '2026-05-01',
    url: 'https://example.com/activity/1',
    address: '台北市信義區',
    distric: '信義區',
    nlat: '25.033',
    elong: '121.565',
    organizer: '台北市政府',
    coRganizer: '',
    contact: '服務人員',
    tel: '02-12345678',
    ticket: '免費',
    traffic: '捷運可達',
    parking: '附近停車場',
    links: [],
  );

  const tPage = ActivityPage(
    total: 1,
    page: 1,
    hasMore: false,
    items: [tActivity],
  );

  group('GetActivitiesUseCase', () {
    test('呼叫 repository.getActivities 並回傳 ActivityPage', () async {
      when(
        () => repository.getActivities(
          lang: 'zh-tw',
          page: 1,
          begin: '2026-05-01',
          end: '2026-05-31',
        ),
      ).thenAnswer((_) async => tPage);

      final result = await useCase(
        lang: 'zh-tw',
        page: 1,
        begin: '2026-05-01',
        end: '2026-05-31',
      );

      expect(result, tPage);
      expect(result.total, 1);
      expect(result.items.first.title, '台北活動');

      verify(
        () => repository.getActivities(
          lang: 'zh-tw',
          page: 1,
          begin: '2026-05-01',
          end: '2026-05-31',
        ),
      ).called(1);

      verifyNoMoreInteractions(repository);
    });

    test('begin / end 為 null 時也能正確呼叫', () async {
      when(
        () => repository.getActivities(
          lang: 'zh-tw',
          page: 1,
          begin: null,
          end: null,
        ),
      ).thenAnswer(
        (_) async =>
            const ActivityPage(total: 0, page: 1, hasMore: false, items: []),
      );

      final result = await useCase(lang: 'zh-tw', page: 1);

      expect(result.items, isEmpty);

      verify(
        () => repository.getActivities(
          lang: 'zh-tw',
          page: 1,
          begin: null,
          end: null,
        ),
      ).called(1);
    });

    test('hasMore = true 時正確回傳', () async {
      const pageWithMore = ActivityPage(
        total: 100,
        page: 1,
        hasMore: true,
        items: [tActivity],
      );

      when(
        () => repository.getActivities(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
          begin: any(named: 'begin'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async => pageWithMore);

      final result = await useCase(lang: 'zh-tw', page: 1);

      expect(result.hasMore, isTrue);
      expect(result.total, 100);
    });

    test('repository 拋出例外時，useCase 同樣拋出', () {
      when(
        () => repository.getActivities(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
          begin: any(named: 'begin'),
          end: any(named: 'end'),
        ),
      ).thenThrow(Exception('network error'));

      expect(() => useCase(lang: 'zh-tw', page: 1), throwsA(isA<Exception>()));
    });
  });
}
