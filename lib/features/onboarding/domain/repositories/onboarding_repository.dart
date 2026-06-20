/// Only describe the business concept of "user onboarding process progress" to the outside world,
/// Do not expose the underlying storage method such as SharedPreferences, DB, or other storage methods.
abstract interface class OnboardingRepository {
  /// Synchronous read. Because the underlying implementation uses SharedPreferencesWithCache,
  /// the key has already been loaded into the cache at startup, so await is not needed here.
  bool hasSeenWelcome();

  /// Marks the bootstrapping process as complete (business semantics),
  /// It's not called markWelcomeAsSeen because it's meant to let the domain say "what business action was performed"
  /// rather than "what value was written to which key".
  Future<void> completeOnboarding();
}
