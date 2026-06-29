import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_logger.dart';
import 'nearby_models.dart';

class LocationState {
  const LocationState({
    required this.permissionState,
    this.cache,
    this.isLoading = false,
    this.errorMessage,
  });

  factory LocationState.initial() =>
      const LocationState(permissionState: NearbyPermissionState.initial);

  final NearbyPermissionState permissionState;
  final LocationCache? cache;
  final bool isLoading;
  final String? errorMessage;

  GeoPoint? get point => cache?.point;

  bool get hasValidLocation => point != null;

  bool get isCacheExpired {
    final c = cache;
    if (c == null) return true;
    return DateTime.now().difference(c.createdAt) > const Duration(minutes: 10);
  }

  LocationState copyWith({
    NearbyPermissionState? permissionState,
    LocationCache? cache,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LocationState(
      permissionState: permissionState ?? this.permissionState,
      cache: cache ?? this.cache,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final locationControllerProvider =
    StateNotifierProvider<LocationController, LocationState>(
      (ref) => LocationController(),
    );

/// This sets the time limit for the native plugin to attempt to obtain high-precision positioning.
/// If this time limit is exceeded, the plugin should theoretically throw a TimeoutException.
const _nativeTimeLimit = Duration(seconds: 12);

/// The hard limit (fuse) on the Dart side.
/// Even if the native timeLimit is not correctly enforced due to bugs on some Android devices/older plugins,
/// This .timeout() will still force the Future to end within its time limit, preventing the UI from spinning indefinitely.
const _hardTimeout = Duration(seconds: 15);

class LocationController extends StateNotifier<LocationState> {
  LocationController() : super(LocationState.initial());

  int _requestId = 0;

  /// Returns the current [GeoPoint] or null on any failure.
  /// Pass [forceRefresh] = true to bypass the 10-minute cache.
  Future<GeoPoint?> getCurrentLocation({bool forceRefresh = false}) async {
    final existing = state.cache;
    if (!forceRefresh && existing != null && !state.isCacheExpired) {
      return existing.point;
    }
    final id = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Check if location services are enabled
      AppLogger.debug('[Location] checking service enabled...');
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (id != _requestId) return null;
        AppLogger.debug('[Location] service disabled');
        state = state.copyWith(
          isLoading: false,
          permissionState: NearbyPermissionState.serviceDisabled,
        );
        return null;
      }
      // Check / Request Permissions
      AppLogger.debug('[Location] checking permission...');
      var perm = await Geolocator.checkPermission();
      AppLogger.debug('[Location] current permission: $perm');
      if (perm == LocationPermission.denied) {
        AppLogger.debug('[Location] requesting permission...');
        perm = await Geolocator.requestPermission();
        AppLogger.debug('[Location] permission after request: $perm');
      }
      if (id != _requestId) return null;
      if (perm == LocationPermission.denied) {
        state = state.copyWith(
          isLoading: false,
          permissionState: NearbyPermissionState.denied,
        );
        return null;
      }
      if (perm == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false,
          permissionState: NearbyPermissionState.deniedForever,
        );
        return null;
      }
      // Get coordinates (double insurance using native timeLimit + Dart .timeout())
      AppLogger.debug('[Location] getting current position...');
      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: _nativeTimeLimit,
          ),
        ).timeout(_hardTimeout);
      } on TimeoutException {
        AppLogger.warning(
          '[Location] getCurrentPosition timed out after '
          '${_hardTimeout.inSeconds}s, falling back to last known position',
        );
        // When you can't get the real-time location, the next best thing is to use the last successful location cache
        final last = await Geolocator.getLastKnownPosition();
        if (id != _requestId) return null;
        if (last == null) {
          state = state.copyWith(
            isLoading: false,
            permissionState: NearbyPermissionState.failure,
            errorMessage: '定位逾時，且裝置上沒有先前的定位快取，請到訊號較好的地方再試一次。',
          );
          return null;
        }
        pos = last;
      }
      AppLogger.debug(
        '[Location] got position: ${pos.latitude}, ${pos.longitude}',
      );
      if (id != _requestId) return null;
      final point = GeoPoint(latitude: pos.latitude, longitude: pos.longitude);
      state = state.copyWith(
        isLoading: false,
        permissionState: NearbyPermissionState.granted,
        cache: LocationCache(point: point, createdAt: DateTime.now()),
        clearError: true,
      );
      return point;
    } catch (e, st) {
      AppLogger.error('[Location] error: $e', exception: e, stackTrace: st);
      if (id != _requestId) return null;
      state = state.copyWith(
        isLoading: false,
        permissionState: NearbyPermissionState.failure,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  void clear() => state = LocationState.initial();
}
