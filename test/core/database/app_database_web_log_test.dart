import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/utils/app_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Stand-in exposing the same two fields Drift's `WasmDatabaseResult` has.
class _FakeDriftResult {
  _FakeDriftResult(this.chosenImplementation, this.missingFeatures);

  final Object chosenImplementation;
  final Set<Object> missingFeatures;
}

void main() {
  setUp(AppLogger.talker.cleanHistory);
  tearDown(AppLogger.talker.cleanHistory);

  group('handleDriftWebResult', () {
    test('logs nothing when no browser features are missing', () {
      handleDriftWebResult(_FakeDriftResult('opfsShared', <Object>{}));

      expect(AppLogger.talker.history, isEmpty);
    });

    test('logs one warning naming the implementation and missing features', () {
      handleDriftWebResult(
        _FakeDriftResult('sharedIndexedDb', <Object>{'sharedArrayBuffers'}),
      );

      final history = AppLogger.talker.history;
      expect(history, hasLength(1));
      expect(history.single.logLevel, LogLevel.warning);
      expect(
        history.single.message,
        'Drift Web using sharedIndexedDb due to '
        'missing browser features: {sharedArrayBuffers}',
      );
    });

    test('lists every missing feature in the message', () {
      handleDriftWebResult(
        _FakeDriftResult('inMemory', <Object>{'opfs', 'sharedArrayBuffers'}),
      );

      expect(
        AppLogger.talker.history.single.message,
        contains('{opfs, sharedArrayBuffers}'),
      );
    });
  });
}
