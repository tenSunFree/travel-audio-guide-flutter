import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/network/network_providers.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/activity/di/activity_providers.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/usecases/get_activities_usecase.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        dioProvider.overrideWithValue(Dio()),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('activityRemoteDataSourceProvider 建立實例', () {
    expect(
      container.read(activityRemoteDataSourceProvider),
      isA<ActivityRemoteDataSource>(),
    );
  });

  test('activityRepositoryProvider 回傳 ActivityRepositoryImpl', () {
    expect(
      container.read(activityRepositoryProvider),
      isA<ActivityRepositoryImpl>(),
    );
  });

  test('getActivitiesUseCaseProvider 正確組裝依賴', () {
    expect(
      container.read(getActivitiesUseCaseProvider),
      isA<GetActivitiesUseCase>(),
    );
  });

  test('activitiesStreamProvider 初始回傳空清單（此 provider 無背景同步，安全）', () async {
    // Riverpod 3: container.read() is no longer considered an active listener.
    // A StreamProvider will be paused if there is no actual listener, and the underlying stream will never actually subscribe or emit.
    // Here, a no-op listener is used to force the provider to remain active,
    // so that .future can actually receive the first value from the underlying stream.
    container.listen(activitiesStreamProvider, (_, _) {});
    final activities = await container.read(activitiesStreamProvider.future);
    expect(activities, isEmpty);
  });
}
