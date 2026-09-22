import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_travel_audio_guide/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._supabase);

  final SupabaseClient _supabase;

  bool _isSigningOut = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final accessToken = _supabase.auth.currentSession?.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    } else {
      AppLogger.info(
        '[AuthInterceptor] 尚未登入，未帶入 Authorization header'
        ' | path=${options.path}',
      );
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    handleUnauthorized(err);
    handler.next(err);
  }

  void handleUnauthorized(DioException err) {
    if (err.response?.statusCode != 401) {
      return;
    }
    AppLogger.info(
      '[AuthInterceptor] Received 401, forcing sign out'
      ' | path=${err.requestOptions.path}',
    );
    if (_isSigningOut) {
      return;
    }
    _isSigningOut = true;
    unawaited(_signOutAfterUnauthorized());
  }

  Future<void> _signOutAfterUnauthorized() async {
    try {
      await _supabase.auth.signOut();
    } catch (error, stackTrace) {
      // Supabase clears the local session before the remote revoke request.
      // A failed revoke must not become an unhandled async error.
      AppLogger.error(
        '[AuthInterceptor] signOut failed after 401',
        exception: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isSigningOut = false;
    }
  }
}
