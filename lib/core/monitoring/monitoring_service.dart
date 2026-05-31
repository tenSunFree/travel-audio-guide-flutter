import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class MonitoringService {
  const MonitoringService._();

  static Future<void> captureException(
    Object exception, {
    StackTrace? stackTrace,
    String? operation,
    // Add a level, preset error, and a warning can be sent if background synchronization fails.
    SentryLevel level = SentryLevel.error,
    Map<String, Object?> extras = const {},
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.level = level;
        if (operation != null) {
          scope.setTag('operation', operation);
        }
        for (final entry in extras.entries) {
          scope.setTag(entry.key, entry.value.toString());
        }
      },
    );
  }

  static Future<void> addBreadcrumb({
    required String message,
    String category = 'app',
    SentryLevel level = SentryLevel.info,
    Map<String, Object?> data = const {},
  }) async {
    await Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        level: level,
        data: data,
      ),
    );
  }

  static ISentrySpan startTransaction({
    required String name,
    required String operation,
    String? description,
  }) {
    return Sentry.startTransaction(
      name,
      operation,
      description: description,
      bindToScope: true,
    );
  }

  static Future<T> monitorFuture<T>({
    required String name,
    required String operation,
    required Future<T> Function() action,
    String? description,
    Map<String, Object?> extras = const {},
  }) async {
    final transaction = startTransaction(
      name: name,
      operation: operation,
      description: description,
    );
    try {
      final result = await action();
      transaction.status = const SpanStatus.ok();
      return result;
    } catch (e, stackTrace) {
      transaction.status = const SpanStatus.internalError();
      await captureException(
        e,
        stackTrace: stackTrace,
        operation: operation,
        extras: extras,
      );
      rethrow;
    } finally {
      await transaction.finish();
    }
  }

  static Future<void> identifyDebugUser() async {
    if (!kDebugMode) return;
    await Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: 'debug-user', username: 'local-debug'));
    });
  }
}
