import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_data_source.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._localDataSource);

  final OnboardingLocalDataSource _localDataSource;

  @override
  bool hasSeenWelcome() => _localDataSource.hasSeenWelcome();

  @override
  Future<void> completeOnboarding() => _localDataSource.markWelcomeAsSeen();
}
