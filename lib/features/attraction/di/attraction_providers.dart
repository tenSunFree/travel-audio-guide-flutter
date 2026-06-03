import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/sync/sync_providers.dart';
import '../data/datasources/attraction_remote_data_source.dart';
import '../data/repositories/attraction_repository_impl.dart';
import '../domain/entities/attraction.dart';
import '../domain/repositories/attraction_repository.dart';
import '../domain/usecases/get_attractions_usecase.dart';
import '../presentation/controllers/attraction_list_controller.dart';

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
