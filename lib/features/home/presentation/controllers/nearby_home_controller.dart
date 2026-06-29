import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/nearby/location_controller.dart';
import '../../../../core/nearby/nearby_models.dart';
import '../../../../core/nearby/nearby_utils.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../activity/di/activity_providers.dart';
import '../../../attraction/di/attraction_providers.dart';
import '../../../attraction/domain/entities/attraction.dart';
import '../../../audio_guide/domain/entities/audio_guide.dart';
import '../../../audio_guide/presentation/controllers/audio_guide_list_controller.dart';
import '../../di/nearby_providers.dart';

// State
class NearbyHomeState {
  const NearbyHomeState({
    this.nearbyAttractions = const [],
    this.nearbyAudioGuides = const [],
    this.isLoading = false,
    this.hasLocation = false,
  });

  final List<Attraction> nearbyAttractions;
  final List<AudioGuide> nearbyAudioGuides;
  final bool isLoading;
  final bool hasLocation;

  NearbyHomeState copyWith({
    List<Attraction>? nearbyAttractions,
    List<AudioGuide>? nearbyAudioGuides,
    bool? isLoading,
    bool? hasLocation,
  }) {
    return NearbyHomeState(
      nearbyAttractions: nearbyAttractions ?? this.nearbyAttractions,
      nearbyAudioGuides: nearbyAudioGuides ?? this.nearbyAudioGuides,
      isLoading: isLoading ?? this.isLoading,
      hasLocation: hasLocation ?? this.hasLocation,
    );
  }
}

class NearbyHomeController extends StateNotifier<NearbyHomeState> {
  // Important fix: The constructor "only performs pure initialization," and does not call any methods that modify the state of other providers (even if wrapped in Future.microtask, it's not safe enough, because the microtask's consumption timing might still fall within the synchronous window of Riverpod's chain initialization of other providers, causing race conditions).
  // The timing for restoring the location is delegated to the UI layer (HomePage) in initState +
  // addPostFrameCallback, explicitly calling restoreIfPreviouslyEnabled(),
  //
  // This ensures that:
  // 1. This provider has been fully mounted
  // 2. The first frame has been built, and no provider is still initializing.
  NearbyHomeController(this._ref) : super(const NearbyHomeState());

  final Ref _ref;

  bool _restoreAttempted = false;

  /// When the app launches/first appears on the homepage: If location was previously allowed, automatically retrieve it again.
  /// Change to public, so the Homepage calls it at a safe time (post frame).
  /// Add the _restoreAttempted flag to prevent it from being triggered repeatedly when the Homepage rebuilds.
  Future<void> restoreIfPreviouslyEnabled() async {
    if (_restoreAttempted) return;
    _restoreAttempted = true;
    final wasEnabled = _ref.read(nearbyRepositoryProvider).isNearbyEnabled();
    if (!wasEnabled) return;
    if (!mounted) return;
    await _silentRefresh();
  }

  // The first time a user clicks "Enable Location Services"
  Future<void> enableNearby() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final point = await _ref
          .read(locationControllerProvider.notifier)
          .getCurrentLocation();
      if (!mounted) return;
      if (point == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      // Remember user authorization; it will be automatically restored on the next startup.
      await _ref.read(nearbyRepositoryProvider).setNearbyEnabled(true);
      await _refresh(point.latitude, point.longitude);
    } catch (e, st) {
      AppLogger.error(
        '[NearbyHome] enableNearby failed',
        exception: e,
        stackTrace: st,
      );
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  // Homepage pull-to-refresh
  Future<void> refresh() async {
    final locState = _ref.read(locationControllerProvider);
    if (locState.permissionState != NearbyPermissionState.granted) return;
    try {
      final point = await _ref
          .read(locationControllerProvider.notifier)
          .getCurrentLocation(forceRefresh: true);
      if (!mounted || point == null) return;
      await _refresh(point.latitude, point.longitude);
    } catch (e, st) {
      AppLogger.error(
        '[NearbyHome] refresh failed',
        exception: e,
        stackTrace: st,
      );
    }
  }

  // Silent restore upon app startup (does not force cache refresh, directly uses cache coordinates)
  Future<void> _silentRefresh() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      final point = await _ref
          .read(locationControllerProvider.notifier)
          .getCurrentLocation();
      if (!mounted) return;
      if (point == null) {
        // Permissions revoked, or location services turned off: Clear memory and display fallback UI.
        await _ref.read(nearbyRepositoryProvider).setNearbyEnabled(false);
        state = state.copyWith(isLoading: false);
        return;
      }
      await _refresh(point.latitude, point.longitude);
    } catch (e, st) {
      AppLogger.error(
        '[NearbyHome] _silentRefresh failed',
        exception: e,
        stackTrace: st,
      );
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  // Core: After obtaining the location, update the homepage and three list pages simultaneously.
  Future<void> _refresh(double userLat, double userLng) async {
    try {
      final db = _ref.read(appDatabaseProvider);
      final attractions = await db.attractionDao.watchAll().first;
      final guides = await db.audioGuideDao.watchAll().first;
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        hasLocation: true,
        nearbyAttractions: _nearbyAttractions(attractions, userLat, userLng),
        nearbyAudioGuides: _nearbyAudioGuides(
          guides: guides,
          attractions: attractions,
          userLat: userLat,
          userLng: userLng,
        ),
      );
      _ref
          .read(attractionListControllerProvider.notifier)
          .applyLocation(userLat, userLng);
      _ref
          .read(activityListControllerProvider.notifier)
          .applyLocation(userLat, userLng);
      _ref
          .read(audioGuideListControllerProvider.notifier)
          .applyLocation(userLat, userLng);
    } catch (e, st) {
      AppLogger.error(
        '[NearbyHome] _refresh failed',
        exception: e,
        stackTrace: st,
      );
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  List<Attraction> _nearbyAttractions(
    List<Attraction> all,
    double userLat,
    double userLng,
  ) {
    for (final maxM in [3000.0, 5000.0, 10000.0]) {
      final bucket = <_Scored<Attraction>>[];
      for (final a in all) {
        if (!NearbyUtils.isValidCoordinate(a.nlat, a.elong)) continue;
        final d = NearbyUtils.distanceMeters(
          fromLat: userLat,
          fromLng: userLng,
          toLat: a.nlat!,
          toLng: a.elong!,
        );
        if (d <= maxM) bucket.add(_Scored(a, d));
      }
      if (bucket.isNotEmpty) {
        bucket.sort((a, b) => a.score.compareTo(b.score));
        return bucket.take(5).map((s) => s.value).toList();
      }
    }
    return [];
  }

  List<AudioGuide> _nearbyAudioGuides({
    required List<AudioGuide> guides,
    required List<Attraction> attractions,
    required double userLat,
    required double userLng,
  }) {
    for (final maxM in [3000.0, 5000.0, 10000.0]) {
      final bucket = <_Scored<AudioGuide>>[];
      for (final g in guides) {
        final d = AudioGuideListState.distanceForGuide(
          guide: g,
          attractions: attractions,
          userLat: userLat,
          userLng: userLng,
        );
        if (d != null && d <= maxM) bucket.add(_Scored(g, d));
      }
      if (bucket.isNotEmpty) {
        bucket.sort((a, b) => a.score.compareTo(b.score));
        return bucket.take(5).map((s) => s.value).toList();
      }
    }
    return [];
  }
}

class _Scored<T> {
  const _Scored(this.value, this.score);

  final T value;
  final double score;
}
