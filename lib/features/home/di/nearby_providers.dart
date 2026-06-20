import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/preferences/shared_preferences_provider.dart';
import '../data/datasources/nearby_local_data_source.dart';
import '../data/repositories/nearby_repository_impl.dart';
import '../domain/repositories/nearby_repository.dart';

final nearbyLocalDataSourceProvider = Provider<NearbyLocalDataSource>((ref) {
  return NearbyLocalDataSource(ref.watch(sharedPreferencesProvider));
});

final nearbyRepositoryProvider = Provider<NearbyRepository>((ref) {
  return NearbyRepositoryImpl(ref.watch(nearbyLocalDataSourceProvider));
});
