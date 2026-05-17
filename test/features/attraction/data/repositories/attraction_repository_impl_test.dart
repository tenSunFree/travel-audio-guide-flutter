import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/datasources/attraction_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/models/attraction_model.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/models/attraction_page_model.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/repositories/attraction_repository_impl.dart';

class MockAttractionRemoteDataSource extends Mock
    implements AttractionRemoteDataSource {}

void main() {
  late MockAttractionRemoteDataSource remoteDataSource;
  late AttractionRepositoryImpl repository;

  setUp(() {
    remoteDataSource = MockAttractionRemoteDataSource();
    repository = AttractionRepositoryImpl(remoteDataSource);
  });

  AttractionModel buildModel({
    int id = 1,
    String name = '台北 101',
    List<AttractionCategoryModel> categories = const [],
    List<AttractionTagModel> targets = const [],
    List<AttractionTagModel> friendlies = const [],
    List<AttractionImageModel> images = const [],
    double? nlat = 25.033,
    double? elong = 121.565,
  }) {
    return AttractionModel(
      id: id,
      name: name,
      introduction: '景點介紹',
      openTime: '09:00-22:00',
      distric: '信義區',
      address: '台北市信義區',
      tel: '02-12345678',
      nlat: nlat,
      elong: elong,
      officialSite: 'https://example.com',
      facebook: '',
      ticket: '免費',
      remind: '',
      modified: '2026-05-01',
      url: 'https://example.com/attraction/$id',
      categories: categories,
      targets: targets,
      friendlies: friendlies,
      images: images,
    );
  }

  group('AttractionRepositoryImpl', () {
    group('getAttractions', () {
      test('正確取得並將 Model 轉換為 Entity（含子結構映射）', () async {
        final pageModel = AttractionPageModel(
          total: 1,
          page: 1,
          data: [
            buildModel(
              categories: [const AttractionCategoryModel(id: 1, name: '自然風景')],
              targets: [const AttractionTagModel(id: 10, name: '親子')],
              friendlies: [const AttractionTagModel(id: 20, name: '無障礙')],
              images: [
                const AttractionImageModel(
                  src: 'https://example.com/image.jpg',
                  subject: '景點圖片',
                  ext: '.jpg',
                ),
              ],
            ),
          ],
        );

        when(
          () => remoteDataSource.getAttractions(
            lang: 'zh-tw',
            page: 1,
            categoryIds: '1',
            nlat: 25.033,
            elong: 121.565,
          ),
        ).thenAnswer((_) async => pageModel);

        final result = await repository.getAttractions(
          lang: 'zh-tw',
          page: 1,
          categoryIds: '1',
          nlat: 25.033,
          elong: 121.565,
        );

        expect(result.total, 1);
        expect(result.page, 1);
        expect(result.data.length, 1);

        final attraction = result.data.first;
        expect(attraction.id, 1);
        expect(attraction.name, '台北 101');

        // Substructure mapping
        expect(attraction.categories.first.name, '自然風景');
        expect(attraction.targets.first.name, '親子');
        expect(attraction.friendlies.first.name, '無障礙');
        expect(attraction.images.first.src, 'https://example.com/image.jpg');

        // Computed properties
        expect(attraction.hasImage, isTrue);
        expect(attraction.hasValidCoordinate, isTrue);
        expect(attraction.categoryText, '自然風景');

        verify(
          () => remoteDataSource.getAttractions(
            lang: 'zh-tw',
            page: 1,
            categoryIds: '1',
            nlat: 25.033,
            elong: 121.565,
          ),
        ).called(1);

        verifyNoMoreInteractions(remoteDataSource);
      });

      test('空資料 → data 為空 List', () async {
        when(
          () => remoteDataSource.getAttractions(
            lang: any(named: 'lang'),
            page: any(named: 'page'),
            categoryIds: any(named: 'categoryIds'),
            nlat: any(named: 'nlat'),
            elong: any(named: 'elong'),
          ),
        ).thenAnswer(
          (_) async => AttractionPageModel(total: 0, page: 1, data: []),
        );

        final result = await repository.getAttractions(lang: 'zh-tw', page: 1);

        expect(result.data, isEmpty);
        expect(result.total, 0);
      });

      test('無圖片時 hasImage = false', () async {
        when(
          () => remoteDataSource.getAttractions(
            lang: any(named: 'lang'),
            page: any(named: 'page'),
            categoryIds: any(named: 'categoryIds'),
            nlat: any(named: 'nlat'),
            elong: any(named: 'elong'),
          ),
        ).thenAnswer(
          (_) async => AttractionPageModel(
            total: 1,
            page: 1,
            data: [buildModel(images: [])],
          ),
        );

        final result = await repository.getAttractions(lang: 'zh-tw', page: 1);

        expect(result.data.first.hasImage, isFalse);
      });

      test('無坐標（nlat/elong 為 null）時 hasValidCoordinate = false', () async {
        when(
          () => remoteDataSource.getAttractions(
            lang: any(named: 'lang'),
            page: any(named: 'page'),
            categoryIds: any(named: 'categoryIds'),
            nlat: any(named: 'nlat'),
            elong: any(named: 'elong'),
          ),
        ).thenAnswer(
          (_) async => AttractionPageModel(
            total: 1,
            page: 1,
            data: [buildModel(nlat: null, elong: null)],
          ),
        );

        final result = await repository.getAttractions(lang: 'zh-tw', page: 1);

        expect(result.data.first.hasValidCoordinate, isFalse);
      });

      test('remote 拋出例外時，repository 同樣拋出', () {
        when(
          () => remoteDataSource.getAttractions(
            lang: any(named: 'lang'),
            page: any(named: 'page'),
            categoryIds: any(named: 'categoryIds'),
            nlat: any(named: 'nlat'),
            elong: any(named: 'elong'),
          ),
        ).thenThrow(Exception('server error'));

        expect(
          () => repository.getAttractions(lang: 'zh-tw', page: 1),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getAttractionCategories', () {
      test('正確取得並將 CategoryModel 轉換為 Entity', () async {
        final categoryModels = [
          const AttractionCategoryModel(id: 1, name: '自然風景'),
          const AttractionCategoryModel(id: 2, name: '親子共遊'),
        ];

        when(
          () => remoteDataSource.getAttractionCategories(lang: 'zh-tw'),
        ).thenAnswer((_) async => categoryModels);

        final result = await repository.getAttractionCategories(lang: 'zh-tw');

        expect(result.length, 2);
        expect(result[0].id, 1);
        expect(result[0].name, '自然風景');
        expect(result[1].id, 2);
        expect(result[1].name, '親子共遊');

        verify(
          () => remoteDataSource.getAttractionCategories(lang: 'zh-tw'),
        ).called(1);

        verifyNoMoreInteractions(remoteDataSource);
      });

      test('分類為空時回傳空 List', () async {
        when(
          () => remoteDataSource.getAttractionCategories(
            lang: any(named: 'lang'),
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getAttractionCategories(lang: 'zh-tw');

        expect(result, isEmpty);
      });

      test('remote 拋出例外時，repository 同樣拋出', () {
        when(
          () => remoteDataSource.getAttractionCategories(
            lang: any(named: 'lang'),
          ),
        ).thenThrow(Exception('categories error'));

        expect(
          () => repository.getAttractionCategories(lang: 'zh-tw'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
