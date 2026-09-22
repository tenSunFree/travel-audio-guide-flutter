import 'package:flutter_travel_audio_guide/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/profile/domain/entities/profile.dart';
import 'package:flutter_travel_audio_guide/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remoteDataSource);

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<Profile> getMe() async {
    final model = await _remoteDataSource.getMe();
    return model.toEntity();
  }

  @override
  Future<Profile> updateMe({
    String? displayName,
    String? avatarUrl,
    String? preferredLanguage,
  }) async {
    final model = await _remoteDataSource.updateMe(
      displayName: displayName,
      avatarUrl: avatarUrl,
      preferredLanguage: preferredLanguage,
    );
    return model.toEntity();
  }
}
