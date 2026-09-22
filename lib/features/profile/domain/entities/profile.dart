import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';

@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String email,
    required String displayName,
    required String preferredLanguage,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? avatarUrl,
  }) = _Profile;

  const Profile._();

  // Avoid leaking PII (email, avatarUrl) into logs via the generated
  // toString(), which TalkerRiverpodObserver prints on every state change.
  @override
  String toString() => 'Profile(id: $id)';
}
