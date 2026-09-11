import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/network/network_providers.dart';
import 'package:flutter_travel_audio_guide/core/sync/sync_providers.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/datasources/attraction_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/repositories/attraction_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/repositories/attraction_repository.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/usecases/get_attractions_usecase.dart';
import 'package:flutter_travel_audio_guide/features/attraction/presentation/controllers/attraction_list_controller.dart';

final attractionRemoteDataSourceProvider = Provider<AttractionRemoteDataSource>(
  (ref) {
    return AttractionRemoteDataSource(ref.watch(dioProvider));
  },
);

final attractionRepositoryProvider = Provider<AttractionRepository>((ref) {
  return AttractionRepositoryImpl(
    ref.watch(attractionRemoteDataSourceProvider),
  );
});

final getAttractionsUseCaseProvider = Provider<GetAttractionsUseCase>((ref) {
  return GetAttractionsUseCase(ref.watch(attractionRepositoryProvider));
});

final attractionListControllerProvider =
    StateNotifierProvider<AttractionListController, AttractionListState>((ref) {
      return AttractionListController(ref: ref);
    });

final attractionsStreamProvider = StreamProvider<List<Attraction>>((ref) {
  // Background synchronization, does not obstruct UI
  Future.microtask(() => ref.read(appSyncServiceProvider).syncAllIfNeeded());
  return ref.watch(appDatabaseProvider).attractionDao.watchAll();
});
