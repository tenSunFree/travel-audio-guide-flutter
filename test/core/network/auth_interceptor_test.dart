import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/network/auth_interceptor.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

class _RecordingErrorHandler extends ErrorInterceptorHandler {
  DioException? nextError;

  @override
  void next(DioException err) {
    nextError = err;
  }
}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late AuthInterceptor interceptor;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    interceptor = AuthInterceptor(client);
  });

  DioException buildError({required int statusCode}) {
    final requestOptions = RequestOptions(path: '/api/v1/me');
    return DioException(
      requestOptions: requestOptions,
      response: Response<void>(
        requestOptions: requestOptions,
        statusCode: statusCode,
      ),
    );
  }

  group('onRequest', () {
    test('已登入時附加 Authorization header', () {
      final session = MockSession();
      when(() => session.accessToken).thenReturn('token-123');
      when(() => auth.currentSession).thenReturn(session);
      final options = RequestOptions(path: '/api/v1/me');
      interceptor.onRequest(options, RequestInterceptorHandler());
      expect(options.headers['Authorization'], 'Bearer token-123');
    });

    test('未登入時不附加 Authorization header', () {
      when(() => auth.currentSession).thenReturn(null);
      final options = RequestOptions(path: '/api/v1/me');
      interceptor.onRequest(options, RequestInterceptorHandler());
      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test('accessToken 為空字串時不附加 Authorization header', () {
      final session = MockSession();
      when(() => session.accessToken).thenReturn('');
      when(() => auth.currentSession).thenReturn(session);
      final options = RequestOptions(path: '/api/v1/me');
      interceptor.onRequest(options, RequestInterceptorHandler());
      expect(options.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('401 handling', () {
    test('onError 收到 401 時觸發 signOut() 並繼續傳遞錯誤', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});
      final err = buildError(statusCode: 401);
      final handler = _RecordingErrorHandler();
      interceptor.onError(err, handler);
      await Future<void>.delayed(Duration.zero);
      verify(() => auth.signOut()).called(1);
      expect(handler.nextError, same(err));
    });

    test('同時收到多個 401 只會觸發一次 signOut()', () async {
      final completer = Completer<void>();
      when(() => auth.signOut()).thenAnswer((_) => completer.future);
      final err = buildError(statusCode: 401);
      interceptor.handleUnauthorized(err);
      interceptor.handleUnauthorized(err);
      await Future<void>.delayed(Duration.zero);
      verify(() => auth.signOut()).called(1);
      completer.complete();
      await Future<void>.delayed(Duration.zero);
    });

    test('非 401 錯誤不會觸發 signOut()', () async {
      interceptor.handleUnauthorized(buildError(statusCode: 500));
      await Future<void>.delayed(Duration.zero);
      verifyNever(() => auth.signOut());
    });

    test('signOut 失敗後仍會重置 flag，下一個 401 可以再次登出', () async {
      final firstSignOut = Completer<void>();
      when(() => auth.signOut()).thenAnswer((_) => firstSignOut.future);
      final err = buildError(statusCode: 401);
      interceptor.handleUnauthorized(err);
      await Future<void>.delayed(Duration.zero);
      // In progress: The second 401 cannot be signed out.
      interceptor.handleUnauthorized(err);
      verify(() => auth.signOut()).called(1);
      firstSignOut.completeError(Exception('network error'));
      await Future<void>.delayed(Duration.zero);
      when(() => auth.signOut()).thenAnswer((_) async {});
      interceptor.handleUnauthorized(err);
      await Future<void>.delayed(Duration.zero);
      verify(() => auth.signOut()).called(1);
    });
  });
}
