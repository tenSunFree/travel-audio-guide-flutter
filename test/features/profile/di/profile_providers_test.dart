import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/network/network_providers.dart';
import 'package:flutter_travel_audio_guide/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/profile/di/profile_providers.dart';
import 'package:flutter_travel_audio_guide/features/profile/domain/repositories/profile_repository.dart';

void main() {
  test('profile providers 用 backend Dio 組出 data source 與 repository', () {
    final container = ProviderContainer(
      overrides: [
        backendDioProvider.overrideWithValue(Dio()),
      ],
    );
    addTearDown(container.dispose);
    expect(
      container.read(profileRemoteDataSourceProvider),
      isA<ProfileRemoteDataSource>(),
    );
    expect(
      container.read(profileRepositoryProvider),
      isA<ProfileRepositoryImpl>(),
    );
    expect(
      container.read(profileRepositoryProvider),
      isA<ProfileRepository>(),
    );
  });
}
