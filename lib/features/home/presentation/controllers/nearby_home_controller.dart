import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/nearby/location_controller.dart';
import '../../../../core/nearby/nearby_models.dart';
import '../../../../core/nearby/nearby_utils.dart';
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

// Controller
class NearbyHomeController extends StateNotifier<NearbyHomeState> {
  NearbyHomeController(this._ref) : super(const NearbyHomeState()) {
    _restoreIfPreviouslyEnabled();
  }

  final Ref _ref;

  // When the app starts
  // If location services were previously allowed, automatically retrieve them again.
  Future<void> _restoreIfPreviouslyEnabled() async {
    final wasEnabled = _ref.read(nearbyRepositoryProvider).isNearbyEnabled();
    if (!wasEnabled) return;
    if (!mounted) return;
    // Directly attempt to retrieve the location (without displaying a permission dialog, since permission was already granted last time)
    // If the user subsequently disables permission in system settings, getCurrentLocation will return null.
    // In this case, keep hasLocation false to ensure the fallback UI displays correctly.
    await _silentRefresh();
  }

  // The first time the user clicks "Enable Location Services"
  Future<void> enableNearby() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    final point = await _ref
        .read(locationControllerProvider.notifier)
        .getCurrentLocation();
    if (!mounted) return;
    if (point == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    // Remember user permission; automatically restore the app the next time it launches.
    await _ref.read(nearbyRepositoryProvider).setNearbyEnabled(true);
    await _refresh(point.latitude, point.longitude);
  }

  // Homepage pull-to-refresh
  Future<void> refresh() async {
    final locState = _ref.read(locationControllerProvider);
    if (locState.permissionState != NearbyPermissionState.granted) return;
    final point = await _ref
        .read(locationControllerProvider.notifier)
        .getCurrentLocation(forceRefresh: true);
    if (!mounted || point == null) return;
    await _refresh(point.latitude, point.longitude);
  }

  // Silent resume upon app launch (do not force refresh of cache, just use cache coordinates)
  Future<void> _silentRefresh() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    final point = await _ref
        .read(locationControllerProvider.notifier)
        .getCurrentLocation(); // Use caching to avoid forced relocation
    if (!mounted) return;
    if (point == null) {
      // Permissions revoked or location service disabled
      // Clear memory and display fallback
      await _ref.read(nearbyRepositoryProvider).setNearbyEnabled(false);
      state = state.copyWith(isLoading: false);
      return;
    }
    await _refresh(point.latitude, point.longitude);
  }

  // Core: After obtaining the location, synchronously update the homepage + three lists.
  Future<void> _refresh(double userLat, double userLng) async {
    final db = _ref.read(appDatabaseProvider);
    final attractions = await db.attractionDao.watchAll().first;
    final guides = await db.audioGuideDao.watchAll().first;
    if (!mounted) return;
    // Update the blocks near the homepage
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
    // Update the coordinates of the three lists simultaneously
    // This way, the distance is already calculated when switching to the attractions/activities/audio guide tab.
    _ref
        .read(attractionListControllerProvider.notifier)
        .applyLocation(userLat, userLng);
    _ref
        .read(activityListControllerProvider.notifier)
        .applyLocation(userLat, userLng);
    _ref
        .read(audioGuideListControllerProvider.notifier)
        .applyLocation(userLat, userLng);
  }

  // Nearby attractions: 3km → 5km → 10km, select up to 5 entries
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

  // Nearby audio guide: 3km → 5km → 10km, select up to 5 routes
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
