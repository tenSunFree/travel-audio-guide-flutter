import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

/// Minimal user information extracted from a Supabase Session.
/// Full profile data (display_name, avatar_url, etc.) is handled by the
/// Profile feature which fetches it from the Go backend (`/api/v1/me`) and
/// is not included here.
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({required String id, required String? email}) =
      _AppUser;
}
