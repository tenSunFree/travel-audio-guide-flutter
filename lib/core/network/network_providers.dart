import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/core/constants/api_constants.dart';
import 'package:flutter_travel_audio_guide/core/constants/backend_api_constants.dart';
import 'package:flutter_travel_audio_guide/core/network/auth_interceptor.dart';
import 'package:flutter_travel_audio_guide/core/network/dio_log_filter.dart';
import 'package:flutter_travel_audio_guide/core/utils/app_logger.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;

  static const _maxRetries = 3;
  static const _retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 3),
    Duration(seconds: 5),
  ];

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = err.requestOptions.extra['_retryAttempt'] as int? ?? 0;
    final statusCode = err.response?.statusCode;
    final is5xx = statusCode != null && statusCode >= 500;
    final isTimeout =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout;
    // If the number of attempts exceeds the limit,
    // or if the error is not 5xx or timeout
    // do not retry, and continue passing the request directly.
    if (attempt >= _maxRetries || (!is5xx && !isTimeout)) {
      return handler.next(err);
    }
    AppLogger.info(
      '[Retry] attempt ${attempt + 1}/$_maxRetries'
      ' | status: $statusCode'
      ' | path: ${err.requestOptions.path}',
    );
    await Future<void>.delayed(_retryDelays[attempt]);
    err.requestOptions.extra['_retryAttempt'] = attempt + 1;
    try {
      final response = await _dio.fetch<dynamic>(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: ApiConstants.defaultHeaders,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
    ),
  );
  // Retry is added first (processed before Sentry records
  // if the retry succeeds, no error will be reported).
  dio.interceptors.add(_RetryInterceptor(dio));
  // Sentry tracing, disable automatic reporting
  // to avoid duplication with _syncIfNeeded.
  dio.addSentry(captureFailedRequests: false);
  // Add at the end of Talker log
  dio.interceptors.add(
    TalkerDioLogger(
      talker: AppLogger.talker,
      settings: const TalkerDioLoggerSettings(
        printRequestHeaders: true,
        requestFilter: DioLogFilter.shouldLogRequest,
        responseFilter: DioLogFilter.shouldLogResponse,
        errorFilter: DioLogFilter.shouldLogError,
      ),
    ),
  );
  return dio;
});

/// For calling Go backend endpoints (/api/v1/*). Automatically includes Supabase JWT.
final backendDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: BackendApiConstants.baseUrl,
      headers: BackendApiConstants.defaultHeaders,
      connectTimeout: BackendApiConstants.connectTimeout,
      receiveTimeout: BackendApiConstants.receiveTimeout,
      sendTimeout: BackendApiConstants.sendTimeout,
    ),
  );
  dio.interceptors.add(AuthInterceptor(Supabase.instance.client));
  dio.addSentry(captureFailedRequests: false);
  dio.interceptors.add(
    TalkerDioLogger(
      talker: AppLogger.talker,
      settings: const TalkerDioLoggerSettings(
        // This client carries the Supabase JWT and profile PII (email,
        // display name, avatar URL) in request/response bodies — never
        // print payloads for it, only method/path/status.
        printRequestData: false,
        printResponseData: false,
        printErrorData: false,
        requestFilter: DioLogFilter.shouldLogRequest,
        responseFilter: DioLogFilter.shouldLogResponse,
        errorFilter: DioLogFilter.shouldLogError,
      ),
    ),
  );
  return dio;
});
