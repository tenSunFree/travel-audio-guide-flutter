import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/preferences/shared_preferences_provider.dart';
import '../data/datasources/onboarding_local_data_source.dart';
import '../data/repositories/onboarding_repository_impl.dart';
import '../domain/repositories/onboarding_repository.dart';

final onboardingLocalDataSourceProvider = Provider<OnboardingLocalDataSource>((
  ref,
) {
  return OnboardingLocalDataSource(ref.watch(sharedPreferencesProvider));
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(ref.watch(onboardingLocalDataSourceProvider));
});

/// Use Notifier to manage the status of "whether the welcome page has been viewed".
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(onboardingRepositoryProvider).hasSeenWelcome();
  }

  Future<void> completeOnboarding() async {
    await ref.read(onboardingRepositoryProvider).completeOnboarding();
    // Modifying the state triggers ref.listen, and then GoRouter refreshListenable completes the URL redirection.
    // WelcomePage does not need to call context.go() itself.
    state = true;
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
