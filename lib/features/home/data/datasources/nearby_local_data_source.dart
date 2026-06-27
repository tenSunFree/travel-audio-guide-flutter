import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/preferences/shared_preferences_provider.dart';

class NearbyLocalDataSource {
  const NearbyLocalDataSource(this._prefs);

  final SharedPreferencesWithCache _prefs;

  bool getNearbyEnabled() =>
      _prefs.getBool(AppPreferenceKeys.nearbyEnabled) ?? false;

  Future<void> setNearbyEnabled(bool value) =>
      _prefs.setBool(AppPreferenceKeys.nearbyEnabled, value);
}
