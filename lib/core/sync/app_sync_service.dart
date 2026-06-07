import '../../features/activity/data/models/activity_model.dart';
import '../../features/attraction/data/models/attraction_model.dart';
import '../../features/audio_guide/data/models/audio_guide_model.dart';
import '../database/app_database.dart';
import '../constants/api_constants.dart';
import '../monitoring/monitoring_service.dart';
import '../utils/app_logger.dart';
import '../../features/attraction/data/datasources/attraction_remote_data_source.dart';
import '../../features/audio_guide/data/datasources/audio_guide_remote_data_source.dart';
import '../../features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

enum SyncTarget { attractions, audioGuides, activities }

class AppSyncService {
  const AppSyncService({
    required this.db,
    required this.attractionRemote,
    required this.audioGuideRemote,
    required this.activityRemote,
  });

  final AppDatabase db;
  final AttractionRemoteDataSource attractionRemote;
  final AudioGuideRemoteDataSource audioGuideRemote;
  final ActivityRemoteDataSource activityRemote;

  static const _attractionKey = 'sync_attractions';
  static const _audioGuideKey = 'sync_audio_guides';
  static const _activityKey = 'sync_activities';
  static const _attractionTtl = Duration(hours: 1);
  static const _audioGuideTtl = Duration(hours: 1);
  static const _activityTtl = Duration(hours: 1);

  Future<void> syncAllIfNeeded() async {
    await MonitoringService.monitorFuture<void>(
      name: 'Sync All If Needed',
      operation: 'offline.sync_all_if_needed',
      description: 'TTL based background sync',
      action: () async {
        await _syncIfNeeded(
          key: _attractionKey,
          ttl: _attractionTtl,
          sync: _syncAttractions,
        );
        await _syncIfNeeded(
          key: _audioGuideKey,
          ttl: _audioGuideTtl,
          sync: _syncAudioGuides,
        );
        await _syncIfNeeded(
          key: _activityKey,
          ttl: _activityTtl,
          sync: _syncActivities,
        );
      },
    );
  }

  Future<void> _syncIfNeeded({
    required String key,
    required Duration ttl,
    required Future<void> Function() sync,
  }) async {
    final lastSyncedAt = await db.syncMetaDao.getLastSyncedAt(key);
    final needSync =
        lastSyncedAt == null || DateTime.now().difference(lastSyncedAt) >= ttl;
    if (!needSync) return;
    try {
      await sync();
      await db.syncMetaDao.saveLastSyncedAt(key);
    } catch (e, st) {
      AppLogger.error('[$key] sync failed', exception: e, stackTrace: st);
      // A warning, not an error
      // will be triggered if the external API fails or if there is an offline cache fallback.
      await MonitoringService.captureException(
        e,
        stackTrace: st,
        operation: 'offline.sync',
        level: SentryLevel.warning,
        extras: {
          'sync_key': key,
          'last_synced_at': lastSyncedAt?.toIso8601String(),
        },
      );
    }
  }

  Future<void> _syncAttractions() async {
    final allRemote = await _fetchAllPages<AttractionModel, dynamic>(
      debugName: 'attractions',
      fetch: (page) => attractionRemote.getAttractions(
        lang: ApiConstants.defaultLang,
        page: page,
      ),
    );
    final localRows = await db.attractionDao.getAll();
    final localModifiedMap = {for (final r in localRows) r.id: r.modified};
    final changed = allRemote
        .where(
          (m) =>
              localModifiedMap[m.id] == null ||
              localModifiedMap[m.id] != m.modified,
        )
        .toList();
    if (changed.isNotEmpty) {
      await db.attractionDao.upsertAll(changed);
      AppLogger.info('Attractions: ${changed.length} updated');
    }
  }

  Future<void> _syncAudioGuides() async {
    final allRemote = await _fetchAllPages<AudioGuideModel, dynamic>(
      debugName: 'audioGuides',
      fetch: (page) => audioGuideRemote.getAudioGuides(
        lang: ApiConstants.defaultLang,
        page: page,
      ),
    );
    final localAttractions = await db.attractionDao.getAll();
    final localRows = await db.audioGuideDao.getAll();
    final localMap = {for (final r in localRows) r.id: r};
    final companions = <AudioGuideTableCompanion>[];
    for (final m in allRemote) {
      final local = localMap[m.id];
      final isNew = local == null;
      final isChanged = local?.modified != m.modified;
      if (isNew || isChanged) {
        final matchedId = _matchAttractionId(
          audioTitle: m.title,
          attractions: localAttractions,
        );
        companions.add(
          db.audioGuideDao.toCompanion(
            m,
            matchedAttractionId: matchedId,
            isDownloaded: local?.isDownloaded ?? false,
            localFilePath: local?.localFilePath,
          ),
        );
      }
    }
    if (companions.isNotEmpty) {
      await db.audioGuideDao.upsertAll(companions);
      AppLogger.info('AudioGuides: ${companions.length} updated');
    }
  }

  Future<void> _syncActivities() async {
    final allRemote = await _fetchAllPages<ActivityModel, dynamic>(
      debugName: 'activities',
      fetch: (page) => activityRemote.getActivities(
        lang: ApiConstants.defaultLang,
        page: page,
      ),
    );
    final localRows = await db.activityDao.getAll();
    final localModifiedMap = {for (final r in localRows) r.id: r.modified};
    final changed = allRemote
        .where(
          (m) =>
              localModifiedMap[m.id] == null ||
              localModifiedMap[m.id] != m.modified,
        )
        .toList();
    if (changed.isNotEmpty) {
      await db.activityDao.upsertAll(changed);
      AppLogger.info('Activities: ${changed.length} updated');
    }
  }

  Future<List<T>> _fetchAllPages<T, P>({
    required Future<P> Function(int page) fetch,
    String debugName = '',
  }) async {
    final all = <T>[];
    var page = 1;
    // Prevent API return errors from causing infinite loops
    const maxPages = 100;
    while (page <= maxPages) {
      final pageModel = await fetch(page);
      final data = (pageModel as dynamic).data as List;
      final total = (pageModel as dynamic).total as int;
      if (data.isEmpty) {
        AppLogger.info('[$debugName] page $page: empty data, stop fetching');
        break;
      }
      all.addAll(data.cast<T>());
      AppLogger.info(
        '[$debugName] page $page: ${data.length} items, total fetched: ${all.length}/$total',
      );
      if (all.length >= total) break;
      page++;
    }
    return all;
  }

  static String _normalize(String s) =>
      s.replaceAll('　', '').replaceAll(' ', '').toLowerCase().trim();

  int? _matchAttractionId({
    required String audioTitle,
    required List<AttractionTableData> attractions,
  }) {
    final normalized = _normalize(audioTitle);
    try {
      return attractions.firstWhere((a) => _normalize(a.name) == normalized).id;
    } catch (_) {
      return null;
    }
  }

  Future<void> forceSync(SyncTarget target) async {
    await MonitoringService.monitorFuture<void>(
      name: 'Force Sync ${target.name}',
      operation: 'offline.force_sync',
      description: target.name,
      extras: {'target': target.name},
      action: () async {
        switch (target) {
          case SyncTarget.attractions:
            await _syncAttractions();
            await db.syncMetaDao.saveLastSyncedAt(_attractionKey);
          case SyncTarget.audioGuides:
            await _syncAudioGuides();
            await db.syncMetaDao.saveLastSyncedAt(_audioGuideKey);
          case SyncTarget.activities:
            await _syncActivities();
            await db.syncMetaDao.saveLastSyncedAt(_activityKey);
        }
      },
    );
  }
}
