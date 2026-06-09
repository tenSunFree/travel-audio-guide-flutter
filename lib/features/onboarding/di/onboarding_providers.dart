import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/onboarding_local_data_source.dart';

/// In main.dart's ProviderScope.overrides, override this provider,
/// so that SharedPreferences is initialized before runApp.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  );
});

final onboardingLocalDataSourceProvider = Provider<OnboardingLocalDataSource>((
  ref,
) {
  return OnboardingLocalDataSource(ref.watch(sharedPreferencesProvider));
});

/// Use Notifier to manage the status of "Have you seen the welcome page?"
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(onboardingLocalDataSourceProvider).hasSeenWelcome();
  }

  Future<void> completeOnboarding() async {
    await ref.read(onboardingLocalDataSourceProvider).markWelcomeAsSeen();
    // Modifying the state triggers ref.listen, and then GoRouter refreshListenable completes the route redirection.
    // WelcomePage does not need to call context.go() itself.
    state = true;
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
