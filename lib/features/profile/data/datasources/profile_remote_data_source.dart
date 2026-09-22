import 'package:dio/dio.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/core/utils/app_logger.dart';
import 'package:flutter_travel_audio_guide/features/profile/data/models/profile_model.dart';

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._dio);

  /// Here [_dio] must point to the Go backend and be an instance with the
  /// AuthInterceptor attached.
  /// (This corresponds to `backendDioProvider` in `network_providers.dart`,
  /// not the dioProvider used for the travel.taipei open-api.)
  final Dio _dio;

  /// GET /api/v1/me
  /// If a profile does not exist, the backend will automatically create one
  /// (preferred_language defaults to 'zh-TW').
  Future<ProfileModel> getMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/me');
      return _parseProfile(response);
    } on DioException catch (e) {
      throw _mapError(e, action: '取得個人資料');
    }
  }

  /// PUT /api/v1/me
  /// Only send the fields you want to update; fields not provided will be
  /// preserved by the backend.
  Future<ProfileModel> updateMe({
    String? displayName,
    String? avatarUrl,
    String? preferredLanguage,
  }) async {
    try {
      final body = <String, dynamic>{
        'display_name': ?displayName,
        'avatar_url': ?avatarUrl,
        'preferred_language': ?preferredLanguage,
      };
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/me',
        data: body,
      );
      return _parseProfile(response);
    } on DioException catch (e) {
      throw _mapError(e, action: '更新個人資料');
    }
  }

  ProfileModel _parseProfile(Response<Map<String, dynamic>> response) {
    final body = response.data;
    final data = body?['data'];
    if (response.statusCode == 200 && data is Map<String, dynamic>) {
      try {
        return ProfileModel.fromJson(data);
      } catch (e, stackTrace) {
        AppLogger.error(
          'Profile API failed | action=解析個人資料 | statusCode=${response.statusCode}',
          exception: e,
          stackTrace: stackTrace,
        );
        Error.throwWithStackTrace(
          const ServerException('個人資料格式錯誤：解析失敗'),
          stackTrace,
        );
      }
    }
    throw ServerException('個人資料格式錯誤：statusCode=${response.statusCode}');
  }

  ServerException _mapError(DioException e, {required String action}) {
    final statusCode = e.response?.statusCode;
    final serverMessage = e.response?.data is Map
        ? (e.response?.data as Map)['error']?.toString()
        : null;
    AppLogger.error(
      'Profile API failed | action=$action | statusCode=$statusCode'
      ' | message=${e.message}',
      exception: e,
      stackTrace: e.stackTrace,
    );
    switch (statusCode) {
      case 401:
        return const ServerException('登入已過期，請重新登入');
      case 403:
        return const ServerException('權杖角色不正確，請重新登入');
      case 404:
        return const ServerException('找不到個人資料，請先呼叫 GET /api/v1/me');
      case 422:
        return ServerException(serverMessage ?? '欄位驗證失敗');
      default:
        return ServerException(serverMessage ?? '$action失敗');
    }
  }
}
