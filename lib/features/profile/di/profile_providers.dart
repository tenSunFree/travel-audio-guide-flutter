import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/core/network/network_providers.dart';
import 'package:flutter_travel_audio_guide/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/profile/domain/repositories/profile_repository.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((
  ref,
) {
  // Note: use backendDioProvider here (targets Go backend + includes JWT),
  // not the dioProvider used for the travel.taipei open-api.
  return ProfileRemoteDataSource(ref.watch(backendDioProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));
});
