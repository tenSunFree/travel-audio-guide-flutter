import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps supabase_flutter's GoTrueClient so the upper layer (Repository)
/// doesn't need to depend directly on supabase_flutter types.
class SupabaseAuthDataSource {
  const SupabaseAuthDataSource(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  /// Emits whenever the Session changes (sign-in, sign-out, or token auto-refresh).
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      AppLogger.error('SupabaseAuth signIn failed: ${e.message}', exception: e);
      throw ServerException(_mapAuthError(e));
    }
  }

  /// Returns the full [AuthResponse] so callers can check whether
  /// `response.session` is null.
  ///
  /// If the Supabase project has email confirmation enabled, `session` will be
  /// null after a successful signup (meaning the account is created but the
  /// user must confirm their email before being fully signed in). Callers
  /// must not treat a successful response as an authenticated state.
  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      AppLogger.error('SupabaseAuth signUp failed: ${e.message}', exception: e);
      throw ServerException(_mapAuthError(e));
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      AppLogger.error(
        'SupabaseAuth signOut failed: ${e.message}',
        exception: e,
      );
      throw ServerException(e.message);
    }
  }

  /// Map common Supabase error codes to user-facing messages in Chinese so
  /// the UI can display them directly.
  String _mapAuthError(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return '帳號或密碼錯誤';
      case 'email_not_confirmed':
        return '請先完成信箱驗證';
      case 'user_already_exists':
        return '此信箱已被註冊';
      case 'weak_password':
        return '密碼強度不足（至少 6 碼）';
      default:
        return e.message;
    }
  }
}
