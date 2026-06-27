import '../../domain/repositories/nearby_repository.dart';
import '../datasources/nearby_local_data_source.dart';

class NearbyRepositoryImpl implements NearbyRepository {
  const NearbyRepositoryImpl(this._localDataSource);

  final NearbyLocalDataSource _localDataSource;

  @override
  bool isNearbyEnabled() => _localDataSource.getNearbyEnabled();

  @override
  Future<void> setNearbyEnabled(bool value) =>
      _localDataSource.setNearbyEnabled(value);
}
