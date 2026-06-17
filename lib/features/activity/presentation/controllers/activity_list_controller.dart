import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/nearby/nearby_models.dart';
import '../../../../core/nearby/nearby_utils.dart';
import '../../../../core/sync/app_sync_service.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../domain/entities/activity.dart';
import '../enums/activity_sort_filter_enums.dart';

enum _ActivityTimeState {
  ongoing, // has precise times, now is between begin and end
  upcomingSoon, // has precise times, starts within 2 hours
  todayOnly, // date-range only, today is within range
  ended,
  unknown,
}

class ActivityListState {
  const ActivityListState({
    required this.allItems,
    required this.items,
    required this.currentPage,
    required this.total,
    required this.hasMore,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.errorMessage,
    required this.sortOrder,
    required this.statusFilter,
    required this.feeFilter,
    required this.distric,
    required this.isSyncing,
    required this.distanceFilter,
    this.userLat,
    this.userLng,
  });

  factory ActivityListState.initial() {
    return const ActivityListState(
      allItems: [],
      items: [],
      currentPage: 0,
      total: 0,
      hasMore: true,
      isInitialLoading: false,
      isLoadingMore: false,
      errorMessage: null,
      sortOrder: ActivitySortOrder.beginAsc,
      statusFilter: ActivityStatusFilter.all,
      feeFilter: ActivityFeeFilter.all,
      distric: '',
      isSyncing: true,
      distanceFilter: DistanceFilter.unlimited,
    );
  }

  final List<Activity> allItems;
  final List<Activity> items;
  final int currentPage;
  final int total;
  final bool hasMore;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final ActivitySortOrder sortOrder;
  final ActivityStatusFilter statusFilter;
  final ActivityFeeFilter feeFilter;
  final String distric;
  final bool isSyncing;
  final DistanceFilter distanceFilter;
  final double? userLat;
  final double? userLng;

  bool get isDefaultFilter =>
      sortOrder == ActivitySortOrder.beginAsc &&
      statusFilter == ActivityStatusFilter.all &&
      feeFilter == ActivityFeeFilter.all &&
      distric.isEmpty &&
      distanceFilter == DistanceFilter.unlimited;

  List<String> get availableDistrics {
    final seen = <String>{};
    final result = <String>[];
    for (final a in allItems) {
      final d = a.distric.trim();
      if (d.isNotEmpty && seen.add(d)) result.add(d);
    }
    result.sort();
    return result;
  }

  static List<Activity> computeDisplayItems(
    List<Activity> rawItems,
    ActivitySortOrder sort,
    ActivityStatusFilter status,
    ActivityFeeFilter fee,
    String distric, {
    required DistanceFilter distanceFilter,
    double? userLat,
    double? userLng,
  }) {
    final now = DateTime.now();
    final filtered = rawItems.where((a) {
      // Status filter
      if (status != ActivityStatusFilter.all) {
        final ts = _activityTimeState(a, now);
        final pass = switch (status) {
          ActivityStatusFilter.all => true,
          ActivityStatusFilter.ongoing => ts == _ActivityTimeState.ongoing,
          ActivityStatusFilter.upcoming =>
            ts == _ActivityTimeState.upcomingSoon,
          ActivityStatusFilter.today => ts == _ActivityTimeState.todayOnly,
        };
        if (!pass) return false;
      }
      // Fee filter
      if (fee != ActivityFeeFilter.all) {
        final isFree = a.ticket.trim().isEmpty;
        if (fee == ActivityFeeFilter.free && !isFree) return false;
        if (fee == ActivityFeeFilter.paid && isFree) return false;
      }
      // District filter
      if (distric.isNotEmpty && a.distric.trim() != distric) return false;
      // Distance filter
      if (distanceFilter != DistanceFilter.unlimited) {
        if (userLat == null || userLng == null) return false;
        final lat = double.tryParse(a.nlat);
        final lng = double.tryParse(a.elong);
        if (!NearbyUtils.isValidCoordinate(lat, lng)) return false;
        final d = NearbyUtils.distanceMeters(
          fromLat: userLat,
          fromLng: userLng,
          toLat: lat!,
          toLng: lng!,
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
    switch (sort) {
      case ActivitySortOrder.beginAsc:
        filtered.sort((a, b) => a.begin.compareTo(b.begin));
      case ActivitySortOrder.beginDesc:
        filtered.sort((a, b) => b.begin.compareTo(a.begin));
      case ActivitySortOrder.nameAZ:
        filtered.sort((a, b) => a.title.compareTo(b.title));
      case ActivitySortOrder.distanceAsc:
        if (userLat != null && userLng != null) {
          filtered.sort((a, b) {
            final ad = _activityDistance(userLat, userLng, a);
            final bd = _activityDistance(userLat, userLng, b);
            return ad.compareTo(bd);
          });
        }
    }
    return filtered;
  }

  // Time state helpers
  static _ActivityTimeState _activityTimeState(Activity a, DateTime now) {
    DateTime? begin;
    DateTime? end;
    try {
      if (a.begin.isNotEmpty) begin = DateTime.parse(_cleanDate(a.begin));
      if (a.end.isNotEmpty) end = DateTime.parse(_cleanDate(a.end));
    } catch (_) {}
    if (begin == null || end == null) return _ActivityTimeState.unknown;
    final hasPrecise = _hasPreciseTime(begin) || _hasPreciseTime(end);
    if (hasPrecise) {
      if (!now.isBefore(begin) && !now.isAfter(end)) {
        return _ActivityTimeState.ongoing;
      }
      if (begin.isAfter(now) &&
          begin.difference(now) <= const Duration(hours: 2)) {
        return _ActivityTimeState.upcomingSoon;
      }
      if (now.isAfter(end)) return _ActivityTimeState.ended;
      return _ActivityTimeState.unknown;
    }
    // Date-range only
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(begin.year, begin.month, begin.day);
    final endDate = DateTime(end.year, end.month, end.day);
    if (!today.isBefore(startDate) && !today.isAfter(endDate)) {
      return _ActivityTimeState.todayOnly;
    }
    return _ActivityTimeState.unknown;
  }

  static bool _hasPreciseTime(DateTime dt) =>
      dt.hour != 0 || dt.minute != 0 || dt.second != 0;

  static String _cleanDate(String raw) =>
      raw.replaceAll(' +08:00', '').replaceAll('/', '-').trim();

  static double _activityDistance(double userLat, double userLng, Activity a) {
    final lat = double.tryParse(a.nlat);
    final lng = double.tryParse(a.elong);
    if (!NearbyUtils.isValidCoordinate(lat, lng)) return double.maxFinite;
    return NearbyUtils.distanceMeters(
      fromLat: userLat,
      fromLng: userLng,
      toLat: lat!,
      toLng: lng!,
    );
  }

  // Public helper used by ActivityTile to build the status badge text.
  // Returns null when no badge should be shown.
  static String? activityStatusText(Activity a, DateTime now) {
    final ts = _activityTimeState(a, now);
    return switch (ts) {
      _ActivityTimeState.ongoing => null,
      _ActivityTimeState.upcomingSoon => '今天稍晚開始',
      _ActivityTimeState.todayOnly => '今日活動',
      _ => null,
    };
  }

  ActivityListState copyWith({
    List<Activity>? allItems,
    List<Activity>? items,
    int? currentPage,
    int? total,
    bool? hasMore,
    bool? isInitialLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearErrorMessage = false,
    ActivitySortOrder? sortOrder,
    ActivityStatusFilter? statusFilter,
    ActivityFeeFilter? feeFilter,
    String? distric,
    bool? isSyncing,
    DistanceFilter? distanceFilter,
    double? userLat,
    double? userLng,
  }) {
    return ActivityListState(
      allItems: allItems ?? this.allItems,
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      sortOrder: sortOrder ?? this.sortOrder,
      statusFilter: statusFilter ?? this.statusFilter,
      feeFilter: feeFilter ?? this.feeFilter,
      distric: distric ?? this.distric,
      isSyncing: isSyncing ?? this.isSyncing,
      distanceFilter: distanceFilter ?? this.distanceFilter,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
    );
  }
}

class ActivityListController extends StateNotifier<ActivityListState> {
  ActivityListController({required this.ref})
    : super(ActivityListState.initial()) {
    _init();
  }

  final Ref ref;
  StreamSubscription<List<Activity>>? _sub;

  void _init() {
    _sub = ref.read(appDatabaseProvider).activityDao.watchAll().listen(_onData);
    Future.microtask(() async {
      try {
        await ref.read(appSyncServiceProvider).syncAllIfNeeded();
      } catch (_) {
      } finally {
        if (mounted) state = state.copyWith(isLoadingMore: false);
      }
    });
  }

  void _onData(List<Activity> all) {
    state = state.copyWith(
      allItems: all,
      items: ActivityListState.computeDisplayItems(
        all,
        state.sortOrder,
        state.statusFilter,
        state.feeFilter,
        state.distric,
        distanceFilter: state.distanceFilter,
        userLat: state.userLat,
        userLng: state.userLng,
      ),
      total: all.length,
      isInitialLoading: false,
      clearErrorMessage: true,
    );
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isInitialLoading: true);
    try {
      await ref.read(appSyncServiceProvider).forceSync(SyncTarget.activities);
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
      items: ActivityListState.computeDisplayItems(
        state.allItems,
        state.sortOrder,
        state.statusFilter,
        state.feeFilter,
        state.distric,
        distanceFilter: state.distanceFilter,
        userLat: lat,
        userLng: lng,
      ),
    );
  }

  void applySortFilter({
    required ActivitySortOrder sortOrder,
    required ActivityStatusFilter statusFilter,
    required ActivityFeeFilter feeFilter,
    required String distric,
    required DistanceFilter distanceFilter,
  }) {
    state = state.copyWith(
      sortOrder: sortOrder,
      statusFilter: statusFilter,
      feeFilter: feeFilter,
      distric: distric,
      distanceFilter: distanceFilter,
      items: ActivityListState.computeDisplayItems(
        state.allItems,
        sortOrder,
        statusFilter,
        feeFilter,
        distric,
        distanceFilter: distanceFilter,
        userLat: state.userLat,
        userLng: state.userLng,
      ),
    );
  }

  void resetSortFilter() {
    applySortFilter(
      sortOrder: ActivitySortOrder.beginAsc,
      statusFilter: ActivityStatusFilter.all,
      feeFilter: ActivityFeeFilter.all,
      distric: '',
      distanceFilter: DistanceFilter.unlimited,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
