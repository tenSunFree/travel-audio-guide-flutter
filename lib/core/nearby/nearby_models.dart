enum DistanceFilter {
  meters500,
  km1,
  km3,
  km5,
  unlimited;

  String get label => switch (this) {
    DistanceFilter.meters500 => '500m',
    DistanceFilter.km1 => '1km',
    DistanceFilter.km3 => '3km',
    DistanceFilter.km5 => '5km',
    DistanceFilter.unlimited => '不限',
  };

  double? get meters => switch (this) {
    DistanceFilter.meters500 => 500,
    DistanceFilter.km1 => 1000,
    DistanceFilter.km3 => 3000,
    DistanceFilter.km5 => 5000,
    DistanceFilter.unlimited => null,
  };
}

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocationCache {
  const LocationCache({required this.point, required this.createdAt});

  final GeoPoint point;
  final DateTime createdAt;
}

enum NearbyPermissionState {
  initial,
  serviceDisabled,
  denied,
  deniedForever,
  granted,
  failure,
}
