import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/network/network_providers.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/audio_guide_local_data_source.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/audio_guide_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/repositories/audio_guide_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/di/audio_guide_providers.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/usecases/download_audio_guide_usecase.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/usecases/get_audio_guides_usecase.dart';

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

  test('audioGuideRemoteDataSourceProvider 建立實例', () {
    expect(
      container.read(audioGuideRemoteDataSourceProvider),
      isA<AudioGuideRemoteDataSource>(),
    );
  });

  test('audioGuideLocalDataSourceProvider 建立實例', () {
    expect(
      container.read(audioGuideLocalDataSourceProvider),
      isA<AudioGuideLocalDataSource>(),
    );
  });

  test('audioGuideRepositoryProvider 回傳 AudioGuideRepositoryImpl', () {
    expect(
      container.read(audioGuideRepositoryProvider),
      isA<AudioGuideRepositoryImpl>(),
    );
  });

  test('getAudioGuidesUseCaseProvider 正確組裝依賴', () {
    expect(
      container.read(getAudioGuidesUseCaseProvider),
      isA<GetAudioGuidesUseCase>(),
    );
  });

  test('downloadAudioGuideUseCaseProvider 正確組裝依賴', () {
    expect(
      container.read(downloadAudioGuideUseCaseProvider),
      isA<DownloadAudioGuideUseCase>(),
    );
  });

  test('audioGuidesStreamProvider 初始回傳空清單（無背景同步，安全）', () async {
    container.listen(audioGuidesStreamProvider, (_, _) {});
    final result = await container.read(audioGuidesStreamProvider.future);
    expect(result, isEmpty);
  });
}
