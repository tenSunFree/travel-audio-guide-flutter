import 'package:flutter_travel_audio_guide/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  /// The currently signed-in user; null when not signed in.
  AppUser? get currentUser;

  /// Whether a user is signed in (has a valid session).
  bool get isSignedIn;

  /// Stream of sign-in / sign-out state changes. The Router listens to this
  /// to perform automatic navigation.
  Stream<bool> get authStateChanges;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password.
  ///
  /// The returned value indicates whether a session was obtained immediately
  /// after sign-up:
  /// - `true`: The Supabase project does not enforce email confirmation, so
  ///   sign-up yields an active session.
  /// - `false`: Email confirmation is required; the account is created but the
  ///   user must confirm via email and is not signed in yet.
  Future<bool> signUpWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
