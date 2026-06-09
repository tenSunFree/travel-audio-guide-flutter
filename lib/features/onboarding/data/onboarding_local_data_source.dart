import 'package:shared_preferences/shared_preferences.dart';

class OnboardingLocalDataSource {
  const OnboardingLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _hasSeenWelcomeKey = 'has_seen_welcome';

  bool hasSeenWelcome() => _prefs.getBool(_hasSeenWelcomeKey) ?? false;

  Future<void> markWelcomeAsSeen() => _prefs.setBool(_hasSeenWelcomeKey, true);
}
