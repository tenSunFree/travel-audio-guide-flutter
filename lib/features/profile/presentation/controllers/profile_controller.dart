import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/profile/di/profile_providers.dart';
import 'package:flutter_travel_audio_guide/features/profile/domain/entities/profile.dart';

/// Attached to the authentication state:
/// - Signed in -> automatically call GET /api/v1/me once.
/// - Signed out -> clear the state.
class ProfileController extends AsyncNotifier<Profile?> {
  /// Request generation for [updateProfile] and [refresh].
  /// [build] increments this when auth changes so in-flight writes are dropped.
  int _requestId = 0;

  @override
  Future<Profile?> build() async {
    // Auth changed -> previous refresh/update must not write state.
    // A stale generation is not the same thing as "signed out".
    ++_requestId;
    final signedIn = await ref.watch(authStateChangesProvider.future);
    if (!signedIn) return null;
    return ref.read(profileRepositoryProvider).getMe();
  }

  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? preferredLanguage,
  }) async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) {
      state = const AsyncData<Profile?>(null);
      return;
    }

    final requestId = ++_requestId;
    state = const AsyncLoading<Profile?>();
    final result = await AsyncValue.guard(
      () => ref
          .read(profileRepositoryProvider)
          .updateMe(
            displayName: displayName,
            avatarUrl: avatarUrl,
            preferredLanguage: preferredLanguage,
          ),
    );
    if (!_shouldCommit(requestId: requestId, userId: userId)) return;
    state = result;
  }

  Future<void> refresh() async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) {
      state = const AsyncData<Profile?>(null);
      return;
    }
    final requestId = ++_requestId;
    state = const AsyncLoading<Profile?>();
    final result = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).getMe(),
    );
    if (!_shouldCommit(requestId: requestId, userId: userId)) return;
    state = result;
  }

  bool _shouldCommit({required int requestId, required String userId}) {
    if (requestId != _requestId) return false;
    return ref.read(authRepositoryProvider).currentUser?.id == userId;
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, Profile?>(
      ProfileController.new,
    );
