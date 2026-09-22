import 'package:flutter_travel_audio_guide/features/profile/domain/entities/profile.dart';

abstract class ProfileRepository {
  Future<Profile> getMe();

  Future<Profile> updateMe({
    String? displayName,
    String? avatarUrl,
    String? preferredLanguage,
  });
}
