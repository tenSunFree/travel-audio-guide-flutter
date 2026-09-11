import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/network/network_providers.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/repositories/activity_repository.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/usecases/get_activities_usecase.dart';
import 'package:flutter_travel_audio_guide/features/activity/presentation/controllers/activity_list_controller.dart';

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
