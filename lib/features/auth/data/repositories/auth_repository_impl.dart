import 'package:flutter_travel_audio_guide/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/entities/app_user.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final SupabaseAuthDataSource _dataSource;

  @override
  AppUser? get currentUser {
    final user = _dataSource.currentUser;
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email);
  }

  @override
  bool get isSignedIn {
    // Session.isExpired is a temporary validity guard for the window
    // between Supabase.initialize() restoring a stale local session and
    // supabase_flutter's background auto-refresh completing. Do NOT call
    // signOut() here just because the session is expired — the SDK will
    // refresh it (or sign the user out itself) and emit a fresh
    // AuthState via onAuthStateChange.
    final session = _dataSource.currentSession;
    return session != null && !session.isExpired;
  }

  @override
  Stream<bool> get authStateChanges => _dataSource.onAuthStateChange.map((
    state,
  ) {
    final session = state.session;
    return session != null && !session.isExpired;
  });

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _dataSource.signInWithPassword(email: email, password: password);
  }

  @override
  Future<bool> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _dataSource.signUpWithPassword(
      email: email,
      password: password,
    );
    return response.session != null;
  }

  @override
  Future<void> signOut() => _dataSource.signOut();
}
