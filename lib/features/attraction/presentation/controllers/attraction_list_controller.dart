import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/nearby/nearby_models.dart';
import '../../../../core/nearby/nearby_utils.dart';
import '../../../../core/sync/app_sync_service.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../home/domain/services/open_time_parser.dart';
import '../../domain/entities/attraction.dart';
import '../enums/attraction_sort_filter_enums.dart';

class AttractionListState {
  const AttractionListState({
    this.allItems = const [],
    this.items = const [],
    this.page = 1,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.sortOrder = AttractionSortOrder.apiOrder,
    this.selectedCategoryIds = const {},
    this.distric = '',
    this.selectedTargets = const {},
    this.selectedFacilities = const {},
    this.userLat,
    this.userLng,
    this.isSyncing,
    this.openNowOnly = false,
    this.timeSlotFilter = AttractionTimeSlotFilter.all,
    this.distanceFilter = DistanceFilter.unlimited,
  });

  final List<Attraction> allItems;
  final List<Attraction> items;
  final int page;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final AttractionSortOrder sortOrder;
  final Set<int> selectedCategoryIds;
  final String distric;
  final Set<AttractionTargetFilter> selectedTargets;
  final Set<AttractionFacilityFilter> selectedFacilities;
  final double? userLat;
  final double? userLng;
  final bool? isSyncing;
  final bool openNowOnly;
  final AttractionTimeSlotFilter timeSlotFilter;
  final DistanceFilter distanceFilter;

  bool get isDefaultFilter =>
      !openNowOnly &&
      timeSlotFilter == AttractionTimeSlotFilter.all &&
      sortOrder == AttractionSortOrder.apiOrder &&
      distanceFilter == DistanceFilter.unlimited &&
      selectedCategoryIds.isEmpty &&
      distric.isEmpty &&
      selectedTargets.isEmpty &&
      selectedFacilities.isEmpty;

  List<String> get availableDistrics {
    final result =
        allItems
            .map((e) => e.distric.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return result;
  }

  List<AttractionCategory> get availableCategories {
    final seen = <int>{};
    final result = <AttractionCategory>[];
    for (final item in allItems) {
      for (final cat in item.categories) {
        if (cat.id != 0 && cat.name.isNotEmpty && seen.add(cat.id)) {
          result.add(cat);
        }
      }
    }
    return result;
  }

  static List<Attraction> computeDisplayItems(
    List<Attraction> source, {
    required AttractionSortOrder sortOrder,
    required Set<int> selectedCategoryIds,
    required String distric,
    required Set<AttractionTargetFilter> selectedTargets,
    required Set<AttractionFacilityFilter> selectedFacilities,
    required bool openNowOnly,
    required AttractionTimeSlotFilter timeSlotFilter,
    required DistanceFilter distanceFilter,
    double? userLat,
    double? userLng,
  }) {
    final now = DateTime.now();
    const parser = OpenTimeParser();
    final filtered = source.where((item) {
      // Open now filter
      if (openNowOnly) {
        final result = parser.parse(item.openTime, now);
        if (!result.isOpenNow) return false;
      }
      // Time slot filter
      if (timeSlotFilter != AttractionTimeSlotFilter.all) {
        if (!_isRecommendedForTimeSlot(item, timeSlotFilter)) return false;
        if (!_isOpenDuringTimeSlot(item.openTime, timeSlotFilter)) return false;
      }
      // Category filter
      if (selectedCategoryIds.isNotEmpty) {
        final itemCatIds = item.categories.map((c) => c.id).toSet();
        if (!selectedCategoryIds.any(itemCatIds.contains)) return false;
      }
      // District filter
      if (distric.isNotEmpty && item.distric.trim() != distric) return false;
      // Target filter
      if (selectedTargets.isNotEmpty) {
        final itemTargetIds = item.targets.map((t) => t.id).toSet();
        if (!selectedTargets.any((f) => itemTargetIds.contains(f.apiId))) {
          return false;
        }
      }
      // Facility filter
      if (selectedFacilities.isNotEmpty) {
        final itemFriendlyIds = item.friendlies.map((f) => f.id).toSet();
        if (!selectedFacilities.any((f) => itemFriendlyIds.contains(f.apiId))) {
          return false;
        }
      }
      // Distance filter — items without valid coords are excluded
      if (distanceFilter != DistanceFilter.unlimited) {
        if (userLat == null || userLng == null) return false;
        if (!NearbyUtils.isValidCoordinate(item.nlat, item.elong)) {
          return false;
        }
        final d = NearbyUtils.distanceMeters(
          fromLat: userLat,
          fromLng: userLng,
          toLat: item.nlat!,
          toLng: item.elong!,
        );
        if (!NearbyUtils.passDistanceFilter(
          distanceMeters: d,
          filter: distanceFilter,
        )) {
          return false;
        }
      }
      return true;
    }).toList();
    switch (sortOrder) {
      case AttractionSortOrder.apiOrder:
        break;
      case AttractionSortOrder.nameAZ:
        filtered.sort((a, b) => a.name.compareTo(b.name));
      case AttractionSortOrder.modifiedNewest:
        filtered.sort((a, b) => b.modified.compareTo(a.modified));
      case AttractionSortOrder.distanceAsc:
        if (userLat != null && userLng != null) {
          filtered.sort((a, b) {
            final ad = _distance(userLat, userLng, a.nlat, a.elong);
            final bd = _distance(userLat, userLng, b.nlat, b.elong);
            return ad.compareTo(bd);
          });
        }
    }
    return filtered;
  }

  // private helpers
  static bool _isRecommendedForTimeSlot(
    Attraction item,
    AttractionTimeSlotFilter slot,
  ) {
    final text = [
      item.name,
      item.introduction,
      item.distric,
      ...item.categories.map((e) => e.name),
      ...item.targets.map((e) => e.name),
    ].join(' ');
    return switch (slot) {
      AttractionTimeSlotFilter.all => true,
      AttractionTimeSlotFilter.morning =>
        text.contains('公園') ||
            text.contains('步道') ||
            text.contains('登山') ||
            text.contains('親子') ||
            text.contains('自然'),
      AttractionTimeSlotFilter.afternoon =>
        text.contains('展館') ||
            text.contains('藝文') ||
            text.contains('商圈') ||
            text.contains('親子') ||
            text.contains('室內'),
      AttractionTimeSlotFilter.evening =>
        text.contains('河岸') ||
            text.contains('商圈') ||
            text.contains('夜景') ||
            text.contains('夕陽') ||
            text.contains('夜市'),
      AttractionTimeSlotFilter.night =>
        text.contains('夜市') ||
            text.contains('夜景') ||
            text.contains('商圈') ||
            text.contains('晚間') ||
            text.contains('展演'),
    };
  }

  static bool _isOpenDuringTimeSlot(
    String openTime,
    AttractionTimeSlotFilter slot,
  ) {
    const parser = OpenTimeParser();
    final now = DateTime.now();
    final sampleTime = switch (slot) {
      AttractionTimeSlotFilter.all => now,
      AttractionTimeSlotFilter.morning => DateTime(
        now.year,
        now.month,
        now.day,
        9,
      ),
      AttractionTimeSlotFilter.afternoon => DateTime(
        now.year,
        now.month,
        now.day,
        14,
      ),
      AttractionTimeSlotFilter.evening => DateTime(
        now.year,
        now.month,
        now.day,
        18,
      ),
      AttractionTimeSlotFilter.night => DateTime(
        now.year,
        now.month,
        now.day,
        21,
      ),
    };
    final result = parser.parse(openTime, sampleTime);
    return result.isOpenNow;
  }

  /// Haversine distance in metres; returns [double.maxFinite] for invalid coords
  /// so that items without coordinates sort to the end.
  static double _distance(
    double userLat,
    double userLng,
    double? lat,
    double? lng,
  ) {
    if (!NearbyUtils.isValidCoordinate(lat, lng)) return double.maxFinite;
    return NearbyUtils.distanceMeters(
      fromLat: userLat,
      fromLng: userLng,
      toLat: lat!,
      toLng: lng!,
    );
  }

  AttractionListState copyWith({
    List<Attraction>? allItems,
    List<Attraction>? items,
    int? page,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearErrorMessage = false,
    AttractionSortOrder? sortOrder,
    Set<int>? selectedCategoryIds,
    String? distric,
    Set<AttractionTargetFilter>? selectedTargets,
    Set<AttractionFacilityFilter>? selectedFacilities,
    double? userLat,
    double? userLng,
    bool? isSyncing,
    bool? openNowOnly,
    AttractionTimeSlotFilter? timeSlotFilter,
    DistanceFilter? distanceFilter,
  }) {
    return AttractionListState(
      allItems: allItems ?? this.allItems,
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      sortOrder: sortOrder ?? this.sortOrder,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      distric: distric ?? this.distric,
      selectedTargets: selectedTargets ?? this.selectedTargets,
      selectedFacilities: selectedFacilities ?? this.selectedFacilities,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      isSyncing: isSyncing ?? this.isSyncing,
      openNowOnly: openNowOnly ?? this.openNowOnly,
      timeSlotFilter: timeSlotFilter ?? this.timeSlotFilter,
      distanceFilter: distanceFilter ?? this.distanceFilter,
    );
  }
}

class AttractionListController extends StateNotifier<AttractionListState> {
  AttractionListController({required this.ref})
    : super(const AttractionListState()) {
    _init();
  }

  final Ref ref;
  StreamSubscription<List<Attraction>>? _sub;

  void _init() {
    _sub = ref
        .read(appDatabaseProvider)
        .attractionDao
        .watchAll()
        .listen(_onData);
    Future.microtask(() async {
      try {
        await ref.read(appSyncServiceProvider).syncAllIfNeeded();
      } catch (_) {
      } finally {
        if (mounted) state = state.copyWith(isSyncing: false);
      }
    });
  }

  void _onData(List<Attraction> all) {
    final filtered = AttractionListState.computeDisplayItems(
      all,
      sortOrder: state.sortOrder,
      selectedCategoryIds: state.selectedCategoryIds,
      distric: state.distric,
      selectedTargets: state.selectedTargets,
      selectedFacilities: state.selectedFacilities,
      openNowOnly: state.openNowOnly,
      timeSlotFilter: state.timeSlotFilter,
      distanceFilter: state.distanceFilter,
      userLat: state.userLat,
      userLng: state.userLng,
    );
    state = state.copyWith(
      allItems: all,
      items: filtered,
      total: all.length,
      isLoading: false,
      clearErrorMessage: true,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(appSyncServiceProvider).forceSync(SyncTarget.attractions);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadInitial() => refresh();

  Future<void> loadMore() async {}

  /// Called when location is obtained — updates coords and re-filters.
  void applyLocation(double lat, double lng) {
    state = state.copyWith(
      userLat: lat,
      userLng: lng,
      items: AttractionListState.computeDisplayItems(
        state.allItems,
        sortOrder: state.sortOrder,
        selectedCategoryIds: state.selectedCategoryIds,
        distric: state.distric,
        selectedTargets: state.selectedTargets,
        selectedFacilities: state.selectedFacilities,
        openNowOnly: state.openNowOnly,
        timeSlotFilter: state.timeSlotFilter,
        distanceFilter: state.distanceFilter,
        userLat: lat,
        userLng: lng,
      ),
    );
  }

  void applySortFilter({
    required AttractionSortOrder sortOrder,
    required Set<int> categoryIds,
    required String distric,
    required Set<AttractionTargetFilter> targets,
    required Set<AttractionFacilityFilter> facilities,
    bool? openNowOnly,
    AttractionTimeSlotFilter? timeSlotFilter,
    DistanceFilter? distanceFilter,
  }) {
    final nextOpenNow = openNowOnly ?? state.openNowOnly;
    final nextSlot = timeSlotFilter ?? state.timeSlotFilter;
    final nextDistance = distanceFilter ?? state.distanceFilter;
    AnalyticsService.logAttractionFiltered(
      sortOrder: sortOrder.name,
      openNow: nextOpenNow,
      timeSlot: nextSlot.name,
      categoryCount: categoryIds.length,
      district: distric,
    );
    state = state.copyWith(
      sortOrder: sortOrder,
      selectedCategoryIds: categoryIds,
      distric: distric,
      selectedTargets: targets,
      selectedFacilities: facilities,
      openNowOnly: nextOpenNow,
      timeSlotFilter: nextSlot,
      distanceFilter: nextDistance,
      items: AttractionListState.computeDisplayItems(
        state.allItems,
        sortOrder: sortOrder,
        selectedCategoryIds: categoryIds,
        distric: distric,
        selectedTargets: targets,
        selectedFacilities: facilities,
        openNowOnly: nextOpenNow,
        timeSlotFilter: nextSlot,
        distanceFilter: nextDistance,
        userLat: state.userLat,
        userLng: state.userLng,
      ),
    );
  }

  void applyHomeEntryFilter({
    bool openNowOnly = false,
    AttractionTimeSlotFilter timeSlotFilter = AttractionTimeSlotFilter.all,
  }) {
    state = state.copyWith(
      openNowOnly: openNowOnly,
      timeSlotFilter: timeSlotFilter,
      items: AttractionListState.computeDisplayItems(
        state.allItems,
        sortOrder: state.sortOrder,
        selectedCategoryIds: state.selectedCategoryIds,
        distric: state.distric,
        selectedTargets: state.selectedTargets,
        selectedFacilities: state.selectedFacilities,
        openNowOnly: openNowOnly,
        timeSlotFilter: timeSlotFilter,
        distanceFilter: state.distanceFilter,
        userLat: state.userLat,
        userLng: state.userLng,
      ),
    );
  }

  void resetFilter() {
    state = state.copyWith(
      sortOrder: AttractionSortOrder.apiOrder,
      selectedCategoryIds: {},
      distric: '',
      selectedTargets: {},
      selectedFacilities: {},
      openNowOnly: false,
      timeSlotFilter: AttractionTimeSlotFilter.all,
      distanceFilter: DistanceFilter.unlimited,
      items: AttractionListState.computeDisplayItems(
        state.allItems,
        sortOrder: AttractionSortOrder.apiOrder,
        selectedCategoryIds: {},
        distric: '',
        selectedTargets: {},
        selectedFacilities: {},
        openNowOnly: false,
        timeSlotFilter: AttractionTimeSlotFilter.all,
        distanceFilter: DistanceFilter.unlimited,
        userLat: state.userLat,
        userLng: state.userLng,
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
