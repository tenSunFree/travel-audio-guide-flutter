import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/preferences/shared_preferences_provider.dart';

/// This is the lowest level module that only interacts with SharedPreferencesWithCache,
/// and does not contain any business logic, making it convenient to replace the entire package with other storage implementations (DB, SecureStorage, etc.) in the future.
class OnboardingLocalDataSource {
  const OnboardingLocalDataSource(this._prefs);

  final SharedPreferencesWithCache _prefs;

  bool hasSeenWelcome() =>
      _prefs.getBool(AppPreferenceKeys.hasSeenWelcome) ?? false;

  Future<void> markWelcomeAsSeen() =>
      _prefs.setBool(AppPreferenceKeys.hasSeenWelcome, true);
}
