import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/network_providers.dart';
import '../data/datasources/activity_remote_data_source.dart';
import '../data/repositories/activity_repository_impl.dart';
import '../domain/entities/activity.dart';
import '../domain/repositories/activity_repository.dart';
import '../domain/usecases/get_activities_usecase.dart';
import '../presentation/controllers/activity_list_controller.dart';

final activityRemoteDataSourceProvider = Provider<ActivityRemoteDataSource>(
  (ref) => ActivityRemoteDataSource(ref.watch(dioProvider)),
);

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepositoryImpl(
    remoteDataSource: ref.watch(activityRemoteDataSourceProvider),
  );
});

final getActivitiesUseCaseProvider = Provider<GetActivitiesUseCase>((ref) {
  return GetActivitiesUseCase(ref.watch(activityRepositoryProvider));
});

final activitiesStreamProvider = StreamProvider<List<Activity>>((ref) {
  return ref.watch(appDatabaseProvider).activityDao.watchAll();
});

final activityListControllerProvider =
    StateNotifierProvider<ActivityListController, ActivityListState>((ref) {
      return ActivityListController(ref: ref);
    });
