import 'package:flutter_travel_audio_guide/core/constants/api_constants.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity_page.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/repositories/activity_repository.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  const ActivityRepositoryImpl({
    required ActivityRemoteDataSource remoteDataSource,
    // ignore: prefer_initializing_formals, public parameter name kept for existing DI/test callers while the field stays private
  }) : _remoteDataSource = remoteDataSource;

  final ActivityRemoteDataSource _remoteDataSource;

  @override
  Future<ActivityPage> getActivities({
    required String lang,
    required int page,
    String? begin,
    String? end,
  }) async {
    final pageModel = await _remoteDataSource.getActivities(
      lang: lang,
      page: page,
      begin: begin,
      end: end,
    );
    final items = pageModel.data.map((m) => m.toEntity()).toList();
    // Check if there are more pages: Number loaded < Total
    final loadedCount = (page - 1) * ApiConstants.pageSize + items.length;
    final hasMore = loadedCount < pageModel.total;
    return ActivityPage(
      total: pageModel.total,
      page: pageModel.page,
      items: items,
      hasMore: hasMore,
    );
  }
}
