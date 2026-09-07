import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/network/network_providers.dart';
import 'package:flutter_travel_audio_guide/core/sync/app_sync_service.dart';
import 'package:flutter_travel_audio_guide/core/sync/sync_providers.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/datasources/attraction_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/repositories/attraction_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/attraction/di/attraction_providers.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/usecases/get_attractions_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSyncService extends Mock implements AppSyncService {}

void main() {
  late AppDatabase db;
  late MockAppSyncService mockSyncService;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockSyncService = MockAppSyncService();
    when(() => mockSyncService.syncAllIfNeeded()).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        dioProvider.overrideWithValue(Dio()),
        // Important: stub out real background sync to avoid calling real APIs during tests
        appSyncServiceProvider.overrideWithValue(mockSyncService),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('attractionRemoteDataSourceProvider 建立實例', () {
    expect(
      container.read(attractionRemoteDataSourceProvider),
      isA<AttractionRemoteDataSource>(),
    );
  });

  test('attractionRepositoryProvider 回傳 AttractionRepositoryImpl', () {
    expect(
      container.read(attractionRepositoryProvider),
      isA<AttractionRepositoryImpl>(),
    );
  });

  test('getAttractionsUseCaseProvider 正確組裝依賴', () {
    expect(
      container.read(getAttractionsUseCaseProvider),
      isA<GetAttractionsUseCase>(),
    );
  });

  test('attractionsStreamProvider 回傳資料庫初始空清單，且會觸發背景同步', () async {
    container.listen(attractionsStreamProvider, (_, _) {});
    final result = await container.read(attractionsStreamProvider.future);
    expect(result, isEmpty);
    await Future<void>.delayed(Duration.zero);
    verify(() => mockSyncService.syncAllIfNeeded()).called(1);
  });
}
