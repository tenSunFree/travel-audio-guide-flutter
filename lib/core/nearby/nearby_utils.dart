import 'dart:math' as math;
import 'nearby_models.dart';

class NearbyUtils {
  const NearbyUtils._();

  static bool isValidCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat == 0.0 && lng == 0.0) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    return true;
  }

  /// Haversine formula — returns distance in metres.
  static double distanceMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    const earthRadius = 6371000.0;
    final dLat = _rad(toLat - fromLat);
    final dLng = _rad(toLng - fromLng);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(fromLat)) *
            math.cos(_rad(toLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _rad(double deg) => deg * math.pi / 180.0;

  /// Returns 你附近 / 850m / 1.2km / 10km+
  static String formatDistance(double meters) {
    if (meters < 100) return '你附近';
    if (meters < 1000) return '${meters.round()}m';
    if (meters < 10000) return '${(meters / 1000).toStringAsFixed(1)}km';
    return '10km+';
  }

  static bool passDistanceFilter({
    required double? distanceMeters,
    required DistanceFilter filter,
  }) {
    final max = filter.meters;
    if (max == null) return true;
    if (distanceMeters == null) return false;
    return distanceMeters <= max;
  }
}
