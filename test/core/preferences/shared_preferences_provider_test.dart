import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/preferences/shared_preferences_provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('AppPreferenceKeys.allowList contains all registered keys', () {
    expect(
      AppPreferenceKeys.allowList,
      contains(AppPreferenceKeys.hasSeenWelcome),
    );
    expect(
      AppPreferenceKeys.allowList,
      contains(AppPreferenceKeys.nearbyEnabled),
    );
  });

  test(
    'sharedPreferencesProvider throws UnimplementedError when not overridden',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        () => container.read(sharedPreferencesProvider),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.exception,
            'exception',
            isA<UnimplementedError>(),
          ),
        ),
      );
    },
  );

  test(
    'createSharedPreferencesWithCache supports reading/writing registered keys',
    () async {
      final cache = await createSharedPreferencesWithCache();
      await cache.setBool(AppPreferenceKeys.hasSeenWelcome, true);
      expect(cache.getBool(AppPreferenceKeys.hasSeenWelcome), isTrue);
    },
  );
}
