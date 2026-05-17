import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction_page.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/repositories/attraction_repository.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/usecases/get_attraction_categories_usecase.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/usecases/get_attractions_usecase.dart';

class MockAttractionRepository extends Mock implements AttractionRepository {}

void main() {
  late MockAttractionRepository repository;

  setUp(() {
    repository = MockAttractionRepository();
  });

  const tAttraction = Attraction(
    id: 1,
    name: '台北 101',
    introduction: '景點介紹',
    openTime: '09:00-22:00',
    distric: '信義區',
    address: '台北市信義區信義路五段7號',
    tel: '02-12345678',
    officialSite: 'https://www.taipei-101.com.tw',
    facebook: '',
    ticket: '觀景台門票另計',
    remind: '',
    modified: '2026-05-01',
    url: 'https://example.com/attraction/1',
    categories: [],
    targets: [],
    friendlies: [],
    images: [],
    nlat: 25.033,
    elong: 121.565,
  );

  const tPage = AttractionPage(total: 1, page: 1, data: [tAttraction]);

  const tCategories = [
    AttractionCategory(id: 1, name: '自然風景'),
    AttractionCategory(id: 2, name: '親子共遊'),
  ];

  group('GetAttractionsUseCase', () {
    late GetAttractionsUseCase useCase;

    setUp(() => useCase = GetAttractionsUseCase(repository));

    test('呼叫 repository.getAttractions 並回傳 AttractionPage', () async {
      when(
        () => repository.getAttractions(
          lang: 'zh-tw',
          page: 1,
          categoryIds: '1,2',
          nlat: 25.033,
          elong: 121.565,
        ),
      ).thenAnswer((_) async => tPage);

      final result = await useCase(
        lang: 'zh-tw',
        page: 1,
        categoryIds: '1,2',
        nlat: 25.033,
        elong: 121.565,
      );

      expect(result, tPage);
      expect(result.data.first.name, '台北 101');
      expect(result.data.first.hasValidCoordinate, isTrue);

      verify(
        () => repository.getAttractions(
          lang: 'zh-tw',
          page: 1,
          categoryIds: '1,2',
          nlat: 25.033,
          elong: 121.565,
        ),
      ).called(1);

      verifyNoMoreInteractions(repository);
    });

    test('預設 lang = zh-tw，null 參數也能正確傳入', () async {
      when(
        () => repository.getAttractions(
          lang: 'zh-tw',
          page: 1,
          categoryIds: null,
          nlat: null,
          elong: null,
        ),
      ).thenAnswer(
        (_) async => const AttractionPage(total: 0, page: 1, data: []),
      );

      final result = await useCase(page: 1);

      expect(result.data, isEmpty);

      verify(
        () => repository.getAttractions(
          lang: 'zh-tw',
          page: 1,
          categoryIds: null,
          nlat: null,
          elong: null,
        ),
      ).called(1);
    });

    test('repository 拋出例外時，useCase 同樣拋出', () {
      when(
        () => repository.getAttractions(
          lang: any(named: 'lang'),
          page: any(named: 'page'),
          categoryIds: any(named: 'categoryIds'),
          nlat: any(named: 'nlat'),
          elong: any(named: 'elong'),
        ),
      ).thenThrow(Exception('network error'));

      expect(() => useCase(lang: 'zh-tw', page: 1), throwsA(isA<Exception>()));
    });
  });

  group('GetAttractionCategoriesUseCase', () {
    late GetAttractionCategoriesUseCase useCase;

    setUp(() => useCase = GetAttractionCategoriesUseCase(repository));

    test('呼叫 repository.getAttractionCategories 並回傳分類列表', () async {
      when(
        () => repository.getAttractionCategories(lang: 'zh-tw'),
      ).thenAnswer((_) async => tCategories);

      final result = await useCase(lang: 'zh-tw');

      expect(result, tCategories);
      expect(result.length, 2);
      expect(result.first.name, '自然風景');

      verify(() => repository.getAttractionCategories(lang: 'zh-tw')).called(1);

      verifyNoMoreInteractions(repository);
    });

    test('分類列表為空時回傳空 List', () async {
      when(
        () => repository.getAttractionCategories(lang: any(named: 'lang')),
      ).thenAnswer((_) async => []);

      final result = await useCase(lang: 'zh-tw');

      expect(result, isEmpty);
    });

    test('repository 拋出例外時，useCase 同樣拋出', () {
      when(
        () => repository.getAttractionCategories(lang: any(named: 'lang')),
      ).thenThrow(Exception('categories error'));

      expect(() => useCase(lang: 'zh-tw'), throwsA(isA<Exception>()));
    });
  });
}
