import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/monitoring/monitoring_service.dart';
import '../../../../core/nearby/nearby_models.dart';
import '../../../../core/nearby/nearby_utils.dart';
import '../../../../core/sync/app_sync_service.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../attraction/domain/entities/attraction.dart';
import '../../di/audio_guide_providers.dart';
import '../../domain/entities/audio_guide.dart';
import '../../domain/usecases/download_audio_guide_usecase.dart';
import '../enums/sort_filter_enums.dart';

// State
class AudioGuideListState {
  const AudioGuideListState({
    required this.allItems,
    required this.items,
    required this.currentPage,
    required this.total,
    required this.hasMore,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.downloadingIds,
    required this.errorMessage,
    required this.sortOrder,
    required this.filterType,
    required this.isSyncing,
    required this.distanceFilter,
    required this.attractions,
    this.userLat,
    this.userLng,
  });

  factory AudioGuideListState.initial() {
    return const AudioGuideListState(
      allItems: [],
      items: [],
      currentPage: 0,
      total: 0,
      hasMore: true,
      isInitialLoading: false,
      isLoadingMore: false,
      downloadingIds: <int>{},
      errorMessage: null,
      sortOrder: SortOrder.dateNewest,
      filterType: FilterType.all,
      isSyncing: true,
      distanceFilter: DistanceFilter.unlimited,
      attractions: [],
    );
  }

  final List<AudioGuide> allItems;
  final List<AudioGuide> items;
  final int currentPage;
  final int total;
  final bool hasMore;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final Set<int> downloadingIds;
  final String? errorMessage;
  final SortOrder sortOrder;
  final FilterType filterType;
  final bool isSyncing;
  final DistanceFilter distanceFilter;
  final List<Attraction> attractions;
  final double? userLat;
  final double? userLng;

  bool get isDefaultFilter =>
      sortOrder == SortOrder.dateNewest &&
      filterType == FilterType.all &&
      distanceFilter == DistanceFilter.unlimited;

  // Core compute
  static List<AudioGuide> computeDisplayItems(
    List<AudioGuide> rawItems,
    SortOrder sort,
    FilterType filter, {
    required DistanceFilter distanceFilter,
    required List<Attraction> attractions,
    double? userLat,
    double? userLng,
  }) {
    // Download filter
    final filtered = switch (filter) {
      FilterType.all => [...rawItems],
      FilterType.downloaded => rawItems.where((g) => g.isDownloaded).toList(),
      FilterType.notDownloaded =>
        rawItems.where((g) => !g.isDownloaded).toList(),
    };
    // Distance filter
    final distanceFiltered = distanceFilter == DistanceFilter.unlimited
        ? filtered
        : filtered.where((guide) {
            if (userLat == null || userLng == null) return false;
            final d = distanceForGuide(
              guide: guide,
              attractions: attractions,
              userLat: userLat,
              userLng: userLng,
            );
            return NearbyUtils.passDistanceFilter(
              distanceMeters: d,
              filter: distanceFilter,
            );
          }).toList();
    // Sort
    switch (sort) {
      case SortOrder.dateNewest:
        distanceFiltered.sort((a, b) => b.modified.compareTo(a.modified));
      case SortOrder.dateOldest:
        distanceFiltered.sort((a, b) => a.modified.compareTo(b.modified));
      case SortOrder.nameAZ:
        distanceFiltered.sort((a, b) => a.title.compareTo(b.title));
      case SortOrder.downloadedFirst:
        distanceFiltered.sort(
          (a, b) => (b.isDownloaded ? 1 : 0) - (a.isDownloaded ? 1 : 0),
        );
      case SortOrder.distanceAsc:
        if (userLat != null && userLng != null) {
          distanceFiltered.sort((a, b) {
            final ad =
                distanceForGuide(
                  guide: a,
                  attractions: attractions,
                  userLat: userLat,
                  userLng: userLng,
                ) ??
                double.maxFinite;
            final bd =
                distanceForGuide(
                  guide: b,
                  attractions: attractions,
                  userLat: userLat,
                  userLng: userLng,
                ) ??
                double.maxFinite;
            return ad.compareTo(bd);
          });
        }
    }

    return distanceFiltered;
  }

  // Distance helper — public so Page can call it for the tile label.
  // Uses matchedAttractionId → nearest related attraction coordinate.
  // Returns null when no valid coordinate can be resolved.
  static double? distanceForGuide({
    required AudioGuide guide,
    required List<Attraction> attractions,
    required double userLat,
    required double userLng,
  }) {
    final attractionId = guide.matchedAttractionId;
    if (attractionId == null) return null;
    Attraction? matched;
    for (final a in attractions) {
      if (a.id == attractionId) {
        matched = a;
        break;
      }
    }
    if (matched == null) return null;
    if (!NearbyUtils.isValidCoordinate(matched.nlat, matched.elong)) {
      return null;
    }
    return NearbyUtils.distanceMeters(
      fromLat: userLat,
      fromLng: userLng,
      toLat: matched.nlat!,
      toLng: matched.elong!,
    );
  }

  AudioGuideListState copyWith({
    List<AudioGuide>? allItems,
    List<AudioGuide>? items,
    int? currentPage,
    int? total,
    bool? hasMore,
    bool? isInitialLoading,
    bool? isLoadingMore,
    Set<int>? downloadingIds,
    String? errorMessage,
    bool clearErrorMessage = false,
    SortOrder? sortOrder,
    FilterType? filterType,
    bool? isSyncing,
    DistanceFilter? distanceFilter,
    List<Attraction>? attractions,
    double? userLat,
    double? userLng,
  }) {
    return AudioGuideListState(
      allItems: allItems ?? this.allItems,
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      downloadingIds: downloadingIds ?? this.downloadingIds,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      sortOrder: sortOrder ?? this.sortOrder,
      filterType: filterType ?? this.filterType,
      isSyncing: isSyncing ?? this.isSyncing,
      distanceFilter: distanceFilter ?? this.distanceFilter,
      attractions: attractions ?? this.attractions,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
    );
  }
}

// Controller
class AudioGuideListController extends StateNotifier<AudioGuideListState> {
  AudioGuideListController({
    required this.ref,
    required DownloadAudioGuideUseCase downloadAudioGuideUseCase,
  }) : _downloadAudioGuideUseCase = downloadAudioGuideUseCase,
       super(AudioGuideListState.initial()) {
    _init();
  }

  final Ref ref;
  final DownloadAudioGuideUseCase _downloadAudioGuideUseCase;
  StreamSubscription<List<AudioGuide>>? _guideSub;
  StreamSubscription<List<Attraction>>? _attractionSub;

  void _init() {
    // Watch audio guides
    _guideSub = ref
        .read(appDatabaseProvider)
        .audioGuideDao
        .watchAll()
        .listen(_onGuideData);
    // Watch attractions — needed for coordinate lookup
    _attractionSub = ref
        .read(appDatabaseProvider)
        .attractionDao
        .watchAll()
        .listen(_onAttractionData);
    Future.microtask(() async {
      try {
        await ref.read(appSyncServiceProvider).syncAllIfNeeded();
      } catch (_) {
      } finally {
        if (mounted) state = state.copyWith(isSyncing: false);
      }
    });
  }

  void _onGuideData(List<AudioGuide> all) {
    state = state.copyWith(
      allItems: all,
      items: AudioGuideListState.computeDisplayItems(
        all,
        state.sortOrder,
        state.filterType,
        distanceFilter: state.distanceFilter,
        attractions: state.attractions,
        userLat: state.userLat,
        userLng: state.userLng,
      ),
      total: all.length,
      isInitialLoading: false,
      clearErrorMessage: true,
    );
  }

  void _onAttractionData(List<Attraction> attractions) {
    if (!mounted) return;
    state = state.copyWith(
      attractions: attractions,
      items: AudioGuideListState.computeDisplayItems(
        state.allItems,
        state.sortOrder,
        state.filterType,
        distanceFilter: state.distanceFilter,
        attractions: attractions,
        userLat: state.userLat,
        userLng: state.userLng,
      ),
    );
  }

  // Pull-to-refresh
  Future<void> loadInitial() async {
    state = state.copyWith(isInitialLoading: true);
    try {
      await ref.read(appSyncServiceProvider).forceSync(SyncTarget.audioGuides);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isInitialLoading: false);
    }
  }

  Future<void> loadMore() async {}

  /// Called when location is obtained — updates coords and re-filters.
  void applyLocation(double lat, double lng) {
    state = state.copyWith(
      userLat: lat,
      userLng: lng,
      items: AudioGuideListState.computeDisplayItems(
        state.allItems,
        state.sortOrder,
        state.filterType,
        distanceFilter: state.distanceFilter,
        attractions: state.attractions,
        userLat: lat,
        userLng: lng,
      ),
    );
  }

  void applySortFilter(
    SortOrder sort,
    FilterType filter, {
    DistanceFilter distanceFilter = DistanceFilter.unlimited,
  }) {
    AnalyticsService.logAudioGuideFiltered(
      sortOrder: sort.name,
      filterType: filter.name,
    );
    state = state.copyWith(
      sortOrder: sort,
      filterType: filter,
      distanceFilter: distanceFilter,
      items: AudioGuideListState.computeDisplayItems(
        state.allItems,
        sort,
        filter,
        distanceFilter: distanceFilter,
        attractions: state.attractions,
        userLat: state.userLat,
        userLng: state.userLng,
      ),
    );
  }

  void resetSortFilter() =>
      applySortFilter(SortOrder.dateNewest, FilterType.all);

  // Download (unchanged logic, preserved exactly)
  Future<String?> downloadGuide(AudioGuide guide) async {
    if (state.downloadingIds.contains(guide.id)) return '該檔案正在下載中';
    state = state.copyWith(downloadingIds: {...state.downloadingIds, guide.id});
    await MonitoringService.addBreadcrumb(
      message: 'Start audio guide download',
      category: 'audio.download',
      data: {
        'guide_id': guide.id,
        'guide_title': guide.title,
        'url': guide.url,
      },
    );
    await AnalyticsService.logAudioGuideDownloadStart(
      id: guide.id,
      title: guide.title,
    );
    try {
      final localPath = await MonitoringService.monitorFuture<String>(
        name: 'Audio Guide Download',
        operation: 'audio.download',
        description: guide.title,
        extras: {
          'guide_id': guide.id,
          'guide_title': guide.title,
          'url': guide.url,
        },
        action: () => _downloadAudioGuideUseCase(guide),
      );
      await ref
          .read(appDatabaseProvider)
          .audioGuideDao
          .markAsDownloaded(id: guide.id, localFilePath: localPath);
      await MonitoringService.addBreadcrumb(
        message: 'Audio guide download success',
        category: 'audio.download',
        data: {'guide_id': guide.id, 'local_path': localPath},
      );
      await AnalyticsService.logAudioGuideDownloadSuccess(
        id: guide.id,
        title: guide.title,
      );
      return null;
    } catch (e, stackTrace) {
      await MonitoringService.captureException(
        e,
        stackTrace: stackTrace,
        operation: 'audio.download',
        extras: {
          'guide_id': guide.id,
          'guide_title': guide.title,
          'url': guide.url,
        },
      );
      await AnalyticsService.logAudioGuideDownloadFailure(
        id: guide.id,
        title: guide.title,
        error: e.toString(),
      );
      return e.toString();
    } finally {
      final ids = {...state.downloadingIds}..remove(guide.id);
      state = state.copyWith(downloadingIds: ids);
    }
  }

  @override
  void dispose() {
    _guideSub?.cancel().ignore();
    _attractionSub?.cancel().ignore();
    super.dispose();
  }
}

// Provider
final audioGuideListControllerProvider =
    StateNotifierProvider<AudioGuideListController, AudioGuideListState>((ref) {
      return AudioGuideListController(
        ref: ref,
        downloadAudioGuideUseCase: ref.watch(downloadAudioGuideUseCaseProvider),
      );
    });
