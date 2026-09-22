import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/analytics/analytics_service.dart';
import 'package:flutter_travel_audio_guide/core/router/app_router.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/entities/app_user.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_travel_audio_guide/features/onboarding/di/onboarding_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._controller);

  final StreamController<bool> _controller;

  @override
  AppUser? get currentUser => null;

  @override
  bool get isSignedIn => false;

  @override
  Stream<bool> get authStateChanges => _controller.stream;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<bool> signUpWithPassword({
    required String email,
    required String password,
  }) async => true;

  @override
  Future<void> signOut() async {}
}

/// A fake OnboardingNotifier that skips the real repository/data source
/// chain entirely and just reports "welcome already seen".
class _FakeOnboardingNotifier extends OnboardingNotifier {
  @override
  bool build() => true;
}

void main() {
  // appRouterProvider's GoRouter wires up AnalyticsService.observer, which
  // touches the real FirebaseAnalytics singleton unless overridden — inject
  // a mock so this stays a pure unit test with no Firebase initialization.
  setUp(() {
    AnalyticsService.debugSetInstance(MockFirebaseAnalytics());
  });

  tearDown(AnalyticsService.debugResetInstance);

  test(
    'appRouterProvider falls back to false when authStateChangesProvider '
    'has not yet emitted a value (StreamProvider is not actively listened '
    'at the point of the synchronous read)',
    () {
      final controller = StreamController<bool>();
      final repository = FakeAuthRepository(controller);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          onboardingProvider.overrideWith(_FakeOnboardingNotifier.new),
        ],
      );
      addTearDown(() {
        container.dispose();
        controller.close();
      });
      // Reading appRouterProvider executes the closure body, including
      // `ref.read(authStateChangesProvider).value ?? false`. At this point
      // authStateChangesProvider has not been actively listened yet (the
      // `ref.listen(...)` call happens right after this line), so under
      // Riverpod 3's provider-pause semantics its `.value` is still null,
      // exercising the `?? false` fallback branch.
      final router = container.read(appRouterProvider);
      expect(router, isA<GoRouter>());
    },
  );
}
