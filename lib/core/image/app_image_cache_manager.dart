import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Global Image Cache Manager (Singleton)
///
/// stalePeriod: 1 hour
/// Tourist attraction images don't change frequently. When they expire in 1 hour, they will be silently updated in the background.
/// This does not affect the screen display (the old cache will still be displayed first).
///
/// maxNrOfCacheObjects: 300
/// The number of images in the attraction, activity, and audio guide list is estimated to not exceed this number.
/// This can be adjusted according to actual needs.
class AppImageCacheManager {
  const AppImageCacheManager._();

  static const _key = 'appImageCache';

  static final CacheManager instance = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(hours: 1),
      maxNrOfCacheObjects: 300,
      repo: JsonCacheInfoRepository(databaseName: _key),
      fileService: HttpFileService(),
    ),
  );
}
