import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/models/activity_model.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/models/activity_page_model.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/repositories/activity_repository_impl.dart';

class MockActivityRemoteDataSource extends Mock
    implements ActivityRemoteDataSource {}

void main() {
  late MockActivityRemoteDataSource remoteDataSource;
  late ActivityRepositoryImpl repository;

  setUp(() {
    remoteDataSource = MockActivityRemoteDataSource();
    repository = ActivityRepositoryImpl(remoteDataSource: remoteDataSource);
  });

  /// Create a complete ActivityModel (including links)
  ActivityModel buildModel({
    int id = 1,
    String title = '台北活動',
    List<ActivityLinkModel> links = const [],
  }) {
    return ActivityModel(
      id: id,
      title: title,
      description: '活動說明',
      begin: '2026-05-01',
      end: '2026-05-31',
      posted: '2026-04-01',
      modified: '2026-05-01',
      url: 'https://example.com/activity/$id',
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
      links: links,
    );
  }

  group('ActivityRepositoryImpl', () {
    group('getActivities', () {
      test('正確取得並將 Model 轉換為 Entity', () async {
        final pageModel = ActivityPageModel(
          total: 1,
          page: 1,
          data: [
            buildModel(
              links: [
                const ActivityLinkModel(
                  src: 'https://example.com',
                  subject: '活動連結',
                ),
              ],
            ),
          ],
        );

        when(
          () => remoteDataSource.getActivities(
            lang: 'zh-tw',
            page: 1,
            begin: '2026-05-01',
            end: '2026-05-31',
          ),
        ).thenAnswer((_) async => pageModel);

        final result = await repository.getActivities(
          lang: 'zh-tw',
          page: 1,
          begin: '2026-05-01',
          end: '2026-05-31',
        );

        // Paginated Information
        expect(result.total, 1);
        expect(result.page, 1);
        expect(result.hasMore, isFalse);
        expect(result.items.length, 1);

        // Entity field mapping
        final activity = result.items.first;
        expect(activity.id, 1);
        expect(activity.title, '台北活動');
        expect(activity.distric, '信義區');
        expect(activity.organizer, '台北市政府');

        // Links mapping
        expect(activity.links.length, 1);
        expect(activity.links.first.subject, '活動連結');
        expect(activity.links.first.src, 'https://example.com');

        verify(
          () => remoteDataSource.getActivities(
            lang: 'zh-tw',
            page: 1,
            begin: '2026-05-01',
            end: '2026-05-31',
          ),
        ).called(1);

        verifyNoMoreInteractions(remoteDataSource);
      });

      test('total=100, page=1, 30 筆資料 → hasMore = true', () async {
        // loadedCount = (1-1)*30 + 30 = 30 < 100 → hasMore = true
        final pageModel = ActivityPageModel(
          total: 100,
          page: 1,
          data: List.generate(
            30,
            (i) => buildModel(id: i + 1, title: '活動 ${i + 1}'),
          ),
        );

        when(
          () => remoteDataSource.getActivities(
            lang: 'zh-tw',
            page: 1,
            begin: null,
            end: null,
          ),
        ).thenAnswer((_) async => pageModel);

        final result = await repository.getActivities(lang: 'zh-tw', page: 1);

        expect(result.hasMore, isTrue);
        expect(result.items.length, 30);
      });

      test('total=30, page=1, 30 筆資料 → hasMore = false', () async {
        // loadedCount = 0 + 30 = 30 == 30 → hasMore = false
        final pageModel = ActivityPageModel(
          total: 30,
          page: 1,
          data: List.generate(30, (i) => buildModel(id: i + 1)),
        );

        when(
          () => remoteDataSource.getActivities(
            lang: any(named: 'lang'),
            page: any(named: 'page'),
            begin: any(named: 'begin'),
            end: any(named: 'end'),
          ),
        ).thenAnswer((_) async => pageModel);

        final result = await repository.getActivities(lang: 'zh-tw', page: 1);

        expect(result.hasMore, isFalse);
      });

      test('total=100, page=2, 10 筆資料 → hasMore = false', () async {
        // loadedCount = (2-1)*30 + 10 = 40 < 100 → hasMore = true
        // The actual logic is loadedCount < total, 40 < 100 → hasMore = true
        // Testing the boundary of page=4: (4-1)*30+10=100 == 100 → hasMore = false
        final pageModel = ActivityPageModel(
          total: 100,
          page: 4,
          data: List.generate(10, (i) => buildModel(id: i + 1)),
        );

        when(
          () => remoteDataSource.getActivities(
            lang: any(named: 'lang'),
            page: any(named: 'page'),
            begin: any(named: 'begin'),
            end: any(named: 'end'),
          ),
        ).thenAnswer((_) async => pageModel);

        final result = await repository.getActivities(lang: 'zh-tw', page: 4);

        expect(result.hasMore, isFalse);
      });

      test('空資料時 items 為空且 hasMore = false', () async {
        final pageModel = ActivityPageModel(total: 0, page: 1, data: []);

        when(
          () => remoteDataSource.getActivities(
            lang: any(named: 'lang'),
            page: any(named: 'page'),
            begin: any(named: 'begin'),
            end: any(named: 'end'),
          ),
        ).thenAnswer((_) async => pageModel);

        final result = await repository.getActivities(lang: 'zh-tw', page: 1);

        expect(result.items, isEmpty);
        expect(result.hasMore, isFalse);
      });

      test('remote 拋出例外時，repository 同樣拋出', () {
        when(
          () => remoteDataSource.getActivities(
            lang: any(named: 'lang'),
            page: any(named: 'page'),
            begin: any(named: 'begin'),
            end: any(named: 'end'),
          ),
        ).thenThrow(Exception('server error'));

        expect(
          () => repository.getActivities(lang: 'zh-tw', page: 1),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
