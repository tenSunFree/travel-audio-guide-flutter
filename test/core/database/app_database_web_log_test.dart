import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/utils/app_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

void main() {
  setUp(AppLogger.talker.cleanHistory);
  tearDown(AppLogger.talker.cleanHistory);

  group('logDriftWebFallback', () {
    test('logs nothing when no browser features are missing', () {
      logDriftWebFallback('opfs', const <Object>[]);

      expect(AppLogger.talker.history, isEmpty);
    });

    test('logs one warning naming the implementation and missing features', () {
      logDriftWebFallback('indexedDb', const <Object>['sharedArrayBuffer']);

      final history = AppLogger.talker.history;
      expect(history, hasLength(1));
      expect(history.single.logLevel, LogLevel.warning);
      expect(
        history.single.message,
        'Drift Web using indexedDb due to '
        'missing browser features: [sharedArrayBuffer]',
      );
    });

    test('lists every missing feature in the message', () {
      logDriftWebFallback('inMemory', const <Object>[
        'opfs',
        'sharedArrayBuffer',
      ]);

      expect(
        AppLogger.talker.history.single.message,
        contains('[opfs, sharedArrayBuffer]'),
      );
    });
  });
}
