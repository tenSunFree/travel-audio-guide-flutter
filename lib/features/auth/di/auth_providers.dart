import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:flutter_travel_audio_guide/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase.initialize() is already called in `bootstrap.dart`,
/// so we directly use the global singleton client here.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final supabaseAuthDataSourceProvider = Provider<SupabaseAuthDataSource>((
  ref,
) {
  return SupabaseAuthDataSource(ref.watch(supabaseClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(supabaseAuthDataSourceProvider));
});

/// Authentication state changes Stream: true = signed in, false = signed out.
/// GoRouter's refreshListenable depends on this provider to automatically
/// redirect routes.
final authStateChangesProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  // Immediately emit the current state to avoid the Stream not having emitted any values when the App just starts.
  return repo.authStateChanges.startWith(repo.isSignedIn);
});

/// Whether the user is currently signed in, for UI decisions (e.g. show
/// sign-in/sign-out buttons). It updates with [authStateChangesProvider]. If
/// the Stream hasn't emitted its first value yet (for example right at
/// app startup), fall back to the repository's synchronous snapshot.
final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.value ?? ref.read(authRepositoryProvider).isSignedIn;
});

extension _StartWith<T> on Stream<T> {
  /// The Stream package doesn't provide startWith, so we implement a small
  /// helper here to avoid adding an rxdart dependency.
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
