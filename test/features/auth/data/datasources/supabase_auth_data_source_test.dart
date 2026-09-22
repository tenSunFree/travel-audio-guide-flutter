import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late SupabaseAuthDataSource dataSource;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    dataSource = SupabaseAuthDataSource(client);
  });

  group('currentSession / currentUser', () {
    test('轉發 SupabaseClient 目前的 Session', () {
      final session = MockSession();
      when(() => auth.currentSession).thenReturn(session);
      expect(dataSource.currentSession, session);
    });

    test('轉發 SupabaseClient 目前的 User', () {
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      expect(dataSource.currentUser, user);
    });
  });

  group('signInWithPassword', () {
    test('成功登入時把參數轉發給 SupabaseClient', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => MockAuthResponse());
      await dataSource.signInWithPassword(email: 'a@b.com', password: '123456');
      verify(
        () => auth.signInWithPassword(email: 'a@b.com', password: '123456'),
      ).called(1);
    });

    test('帳密錯誤時轉成中文錯誤訊息並包成 ServerException', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthException(
          'Invalid login credentials',
          code: 'invalid_credentials',
        ),
      );
      expect(
        () => dataSource.signInWithPassword(email: 'a@b.com', password: 'x'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            '帳號或密碼錯誤',
          ),
        ),
      );
    });

    test('未知錯誤代碼時直接沿用 Supabase 原始訊息', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('some other failure', code: 'weird'));
      expect(
        () => dataSource.signInWithPassword(email: 'a@b.com', password: 'x'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'some other failure',
          ),
        ),
      );
    });
  });

  group('signUpWithPassword', () {
    test('成功時回傳完整的 AuthResponse（不只是 void）', () async {
      final response = MockAuthResponse();
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);
      final result = await dataSource.signUpWithPassword(
        email: 'a@b.com',
        password: '123456',
      );
      expect(result, same(response));
    });

    test('信箱已被註冊時轉成中文錯誤訊息', () async {
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthException(
          'User already registered',
          code: 'user_already_exists',
        ),
      );
      expect(
        () => dataSource.signUpWithPassword(email: 'a@b.com', password: 'x'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            '此信箱已被註冊',
          ),
        ),
      );
    });

    test('密碼強度不足時轉成中文錯誤訊息', () async {
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthException('Password too weak', code: 'weak_password'),
      );
      expect(
        () => dataSource.signUpWithPassword(email: 'a@b.com', password: '1'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            '密碼強度不足（至少 6 碼）',
          ),
        ),
      );
    });
  });

  group('signOut', () {
    test('成功登出時轉發給 SupabaseClient', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});
      await dataSource.signOut();
      verify(() => auth.signOut()).called(1);
    });

    test('登出失敗時拋出 ServerException', () async {
      when(
        () => auth.signOut(),
      ).thenThrow(const AuthException('network error'));
      expect(() => dataSource.signOut(), throwsA(isA<ServerException>()));
    });
  });
}
