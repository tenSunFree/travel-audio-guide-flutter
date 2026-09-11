import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/entities/app_user.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._controller, {this.initialIsSignedIn = false});

  final StreamController<bool> _controller;
  final bool initialIsSignedIn;

  @override
  AppUser? get currentUser => null;

  @override
  bool get isSignedIn => initialIsSignedIn;

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

void main() {
  test('isSignedInProvider 會跟著 authStateChangesProvider 即時更新', () async {
    final controller = StreamController<bool>();
    final repository = FakeAuthRepository(controller);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() {
      container.dispose();
      controller.close();
    });
    // Set up a listener to ensure that the underlying StreamProvider actually starts subscribing.
    container.listen(isSignedInProvider, (previous, next) {});
    // Revert to a synchronous snapshot of the repository before the Stream has emitted any values (false).
    expect(container.read(isSignedInProvider), isFalse);
    controller.add(true);
    await pumpEventQueue();
    expect(container.read(isSignedInProvider), isTrue);
    controller.add(false);
    await pumpEventQueue();
    expect(container.read(isSignedInProvider), isFalse);
  });

  test('repository.isSignedIn 為 true 時，起始同步快照也是 true', () {
    final controller = StreamController<bool>();
    final repository = FakeAuthRepository(controller, initialIsSignedIn: true);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() {
      container.dispose();
      controller.close();
    });
    expect(container.read(isSignedInProvider), isTrue);
  });
}
