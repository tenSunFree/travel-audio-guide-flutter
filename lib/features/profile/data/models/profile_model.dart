import 'package:flutter_travel_audio_guide/features/profile/domain/entities/profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_model.freezed.dart';

part 'profile_model.g.dart';

/// Corresponds to the backend's `data` object returned by `GET/PUT /api/v1/me`:
/// {
///   "id": "...", "email": "...", "display_name": "...",
///   "avatar_url": null, "preferred_language": "zh-TW",
///   "created_at": "...", "updated_at": "..."
/// }
@freezed
abstract class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    required String id,
    required String email,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'display_name') @Default('') String displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'preferred_language')
    @Default('zh-TW')
    String preferredLanguage,
  }) = _ProfileModel;

  const ProfileModel._();

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);

  // Avoid leaking PII (email, avatarUrl) into logs via the generated
  // toString(), which TalkerDioLogger / TalkerRiverpodObserver may print.
  @override
  String toString() => 'ProfileModel(id: $id)';

  Profile toEntity() => Profile(
    id: id,
    email: email,
    displayName: displayName,
    avatarUrl: avatarUrl,
    preferredLanguage: preferredLanguage,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
