import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// This declares all SharedPreferences keys used in this project.
///
/// SharedPreferencesWithCache needs to decide which keys are allowed to be read and written during create(),
/// Therefore, when adding a key for each feature, remember to register it here as well,
/// Otherwise, calling get/set on LocalDataSource will directly throw an ArgumentError.
class AppPreferenceKeys {
  const AppPreferenceKeys._();

  // onboarding
  static const hasSeenWelcome = 'has_seen_welcome';

  // home / nearby
  static const nearbyEnabled = 'nearby_enabled';

  static const Set<String> allowList = {hasSeenWelcome, nearbyEnabled};
}

/// Complete await in main.dart before runApp,
/// Feed it in through ProviderScope.overrides to ensure that the first frame can read the value synchronously.
final sharedPreferencesProvider = Provider<SharedPreferencesWithCache>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  );
});

/// The initialization method called by main.dart.
Future<SharedPreferencesWithCache> createSharedPreferencesWithCache() {
  return SharedPreferencesWithCache.create(
    cacheOptions: SharedPreferencesWithCacheOptions(
      allowList: AppPreferenceKeys.allowList,
    ),
  );
}
