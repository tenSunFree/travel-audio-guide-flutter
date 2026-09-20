import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:flutter_travel_audio_guide/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseAuthDataSource extends Mock
    implements SupabaseAuthDataSource {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockAuthState extends Mock implements AuthState {}

/// Creates a MockSession with `isExpired` stubbed.
///
/// AuthRepositoryImpl checks `session.isExpired`. Since mocktail returns `null`
/// for unstubbed boolean getters—triggering a "Null is not a subtype of bool"
/// error—the expiration status must be explicitly specified for every MockSession.
///
/// Note: Do not call `buildSession(...)` directly within the arguments of
/// `when(...).thenReturn(...)`, as this triggers mocktail's
/// "Cannot call `when` within a stub response" error.
/// Assign the result to a variable first, then pass it to `thenReturn`.
MockSession buildSession({required bool expired}) {
  final session = MockSession();
  when(() => session.isExpired).thenReturn(expired);
  return session;
}

void main() {
  late MockSupabaseAuthDataSource dataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    dataSource = MockSupabaseAuthDataSource();
    repository = AuthRepositoryImpl(dataSource);
  });

  group('currentUser', () {
    test('dataSource 沒有登入使用者時回傳 null', () {
      when(() => dataSource.currentUser).thenReturn(null);
      expect(repository.currentUser, isNull);
    });

    test('把 supabase User 映射成 AppUser', () {
      final user = MockUser();
      when(() => user.id).thenReturn('uid-1');
      when(() => user.email).thenReturn('a@b.com');
      when(() => dataSource.currentUser).thenReturn(user);
      final appUser = repository.currentUser;
      expect(appUser?.id, 'uid-1');
      expect(appUser?.email, 'a@b.com');
    });
  });

  group('isSignedIn', () {
    test('currentSession 為 null 時回傳 false', () {
      when(() => dataSource.currentSession).thenReturn(null);
      expect(repository.isSignedIn, isFalse);
    });

    test('currentSession 有值且未過期時回傳 true', () {
      final session = buildSession(expired: false);
      when(() => dataSource.currentSession).thenReturn(session);
      expect(repository.isSignedIn, isTrue);
    });

    test('currentSession 已過期時回傳 false（等 SDK 自動 refresh）', () {
      final session = buildSession(expired: true);
      when(() => dataSource.currentSession).thenReturn(session);
      expect(repository.isSignedIn, isFalse);
    });
  });

  group('authStateChanges', () {
    test('把 AuthState 映射成「session 是否存在且未過期」的 bool stream', () async {
      final validSession = buildSession(expired: false);
      final expiredSession = buildSession(expired: true);
      final signedInState = MockAuthState();
      when(() => signedInState.session).thenReturn(validSession);
      final expiredState = MockAuthState();
      when(() => expiredState.session).thenReturn(expiredSession);
      final signedOutState = MockAuthState();
      when(() => signedOutState.session).thenReturn(null);
      when(() => dataSource.onAuthStateChange).thenAnswer(
        (_) =>
            Stream.fromIterable([signedInState, expiredState, signedOutState]),
      );
      final results = await repository.authStateChanges.toList();
      expect(results, [true, false, false]);
    });
  });

  group('signInWithPassword', () {
    test('轉發參數給 dataSource', () async {
      when(
        () => dataSource.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      await repository.signInWithPassword(email: 'a@b.com', password: '123456');
      verify(
        () => dataSource.signInWithPassword(
          email: 'a@b.com',
          password: '123456',
        ),
      ).called(1);
    });
  });

  group('signUpWithPassword', () {
    test('AuthResponse.session 有值時回傳 true（已直接登入）', () async {
      final response = MockAuthResponse();
      when(() => response.session).thenReturn(MockSession());
      when(
        () => dataSource.signUpWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);
      final result = await repository.signUpWithPassword(
        email: 'a@b.com',
        password: '123456',
      );
      expect(result, isTrue);
    });

    test('AuthResponse.session 為 null 時回傳 false（需要 Email 驗證）', () async {
      final response = MockAuthResponse();
      when(() => response.session).thenReturn(null);
      when(
        () => dataSource.signUpWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);
      final result = await repository.signUpWithPassword(
        email: 'a@b.com',
        password: '123456',
      );
      expect(result, isFalse);
    });
  });

  group('signOut', () {
    test('轉發給 dataSource', () async {
      when(() => dataSource.signOut()).thenAnswer((_) async {});
      await repository.signOut();
      verify(() => dataSource.signOut()).called(1);
    });
  });
}
