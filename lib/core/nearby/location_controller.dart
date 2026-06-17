import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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
      // Check location service
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (id != _requestId) return null;
        state = state.copyWith(
          isLoading: false,
          permissionState: NearbyPermissionState.serviceDisabled,
        );
        return null;
      }
      // Check / request permission
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
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
      // Get position
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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
    } catch (e) {
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
