/// An abstraction of the business concept of "whether the user has ever enabled location services for nearby attractions".
abstract interface class NearbyRepository {
  bool isNearbyEnabled();

  Future<void> setNearbyEnabled(bool value);
}
