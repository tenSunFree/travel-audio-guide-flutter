import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late ProfileRemoteDataSource dataSource;

  setUp(() {
    dio = MockDio();
    dataSource = ProfileRemoteDataSource(dio);
  });

  const profileJson = {
    'id': 'uid-1',
    'email': 'a@b.com',
    'display_name': 'Sun',
    'avatar_url': null,
    'preferred_language': 'zh-TW',
    'created_at': '2026-08-26T00:00:00.000Z',
    'updated_at': '2026-08-26T00:00:00.000Z',
  };

  Response<Map<String, dynamic>> buildResponse({
    required int statusCode,
    Map<String, dynamic>? data,
  }) {
    return Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: '/api/v1/me'),
      statusCode: statusCode,
      data: data,
    );
  }

  DioException buildDioException({
    required int statusCode,
    Object? data,
  }) {
    final requestOptions = RequestOptions(path: '/api/v1/me');
    return DioException(
      requestOptions: requestOptions,
      response: Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: statusCode,
        data: data,
      ),
    );
  }

  test('getMe 成功時解析 ProfileModel', () async {
    when(() => dio.get<Map<String, dynamic>>('/api/v1/me')).thenAnswer(
      (_) async => buildResponse(
        statusCode: 200,
        data: {'data': profileJson},
      ),
    );
    final result = await dataSource.getMe();
    expect(result.id, 'uid-1');
    expect(result.displayName, 'Sun');
  });

  test('getMe 200 但 data 格式錯誤時拋 ServerException', () async {
    when(() => dio.get<Map<String, dynamic>>('/api/v1/me')).thenAnswer(
      (_) async => buildResponse(statusCode: 200, data: {'data': 'oops'}),
    );
    await expectLater(dataSource.getMe(), throwsA(isA<ServerException>()));
  });

  test('getMe 200 且 data 是 Map 但缺必填欄位時，捕捉解析例外並拋 ServerException', () async {
    when(() => dio.get<Map<String, dynamic>>('/api/v1/me')).thenAnswer(
      (_) async => buildResponse(
        statusCode: 200,
        // 缺少 required 的 id/created_at/updated_at，會讓 fromJson 丟例外
        data: {
          'data': <String, dynamic>{'email': 'a@b.com'},
        },
      ),
    );
    await expectLater(
      dataSource.getMe(),
      throwsA(
        isA<ServerException>().having(
          (e) => e.message,
          'message',
          '個人資料格式錯誤：解析失敗',
        ),
      ),
    );
  });

  test('updateMe 只送出非 null 欄位', () async {
    when(
      () => dio.put<Map<String, dynamic>>(
        '/api/v1/me',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => buildResponse(
        statusCode: 200,
        data: {
          'data': {...profileJson, 'display_name': 'Sun2'},
        },
      ),
    );
    final result = await dataSource.updateMe(displayName: 'Sun2');
    expect(result.displayName, 'Sun2');
    final captured =
        verify(
              () => dio.put<Map<String, dynamic>>(
                '/api/v1/me',
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(captured, {'display_name': 'Sun2'});
  });

  group('error mapping', () {
    final cases = <(int, String)>[
      (401, '登入已過期，請重新登入'),
      (403, '權杖角色不正確，請重新登入'),
      (404, '找不到個人資料，請先呼叫 GET /api/v1/me'),
    ];
    for (final testCase in cases) {
      test('${testCase.$1} maps correctly', () async {
        when(
          () => dio.get<Map<String, dynamic>>('/api/v1/me'),
        ).thenThrow(buildDioException(statusCode: testCase.$1));
        await expectLater(
          dataSource.getMe(),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              testCase.$2,
            ),
          ),
        );
      });
    }

    test('422 優先使用後端 error 字串', () async {
      when(
        () => dio.put<Map<String, dynamic>>(
          '/api/v1/me',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        buildDioException(
          statusCode: 422,
          data: {'error': 'display_name too long'},
        ),
      );
      await expectLater(
        dataSource.updateMe(displayName: 'x' * 100),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'display_name too long',
          ),
        ),
      );
    });

    test('未知狀態碼沒有後端 error 時使用 action 失敗訊息', () async {
      when(
        () => dio.put<Map<String, dynamic>>(
          '/api/v1/me',
          data: any(named: 'data'),
        ),
      ).thenThrow(buildDioException(statusCode: 500));
      await expectLater(
        dataSource.updateMe(displayName: 'New'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            '更新個人資料失敗',
          ),
        ),
      );
    });
  });

  test('updateMe 傳入 avatarUrl 與 preferredLanguage 時也會送出這些欄位', () async {
    when(
      () => dio.put<Map<String, dynamic>>(
        '/api/v1/me',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => buildResponse(
        statusCode: 200,
        data: {
          ...{'data': profileJson},
        },
      ),
    );
    await dataSource.updateMe(
      avatarUrl: 'https://example.com/new.png',
      preferredLanguage: 'en',
    );
    final captured =
        verify(
              () => dio.put<Map<String, dynamic>>(
                '/api/v1/me',
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(captured, {
      'avatar_url': 'https://example.com/new.png',
      'preferred_language': 'en',
    });
  });
}
