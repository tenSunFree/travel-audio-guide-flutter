import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/entities/app_user.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_travel_audio_guide/features/auth/presentation/controllers/login_controller.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.signInError,
    this.signUpResult = true,
    this.signUpError,
  });

  Object? signInError;
  final bool signUpResult;
  final Object? signUpError;

  int signInCallCount = 0;
  int signUpCallCount = 0;

  @override
  AppUser? get currentUser => null;

  @override
  bool get isSignedIn => false;

  @override
  Stream<bool> get authStateChanges => const Stream.empty();

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    if (signInError != null) throw signInError!;
  }

  @override
  Future<bool> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    signUpCallCount++;
    if (signUpError != null) throw signUpError!;
    return signUpResult;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  ProviderContainer buildContainer(FakeAuthRepository repository) {
    return ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
  }

  group('signIn', () {
    test('成功時 isSuccess=true 且 needsEmailConfirmation 恆為 false', () async {
      final repository = FakeAuthRepository();
      final container = buildContainer(repository);
      addTearDown(container.dispose);
      await container
          .read(loginControllerProvider.notifier)
          .signIn(email: 'a@b.com', password: '123456');
      final state = container.read(loginControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isTrue);
      expect(state.needsEmailConfirmation, isFalse);
      expect(state.errorMessage, isNull);
      expect(repository.signInCallCount, 1);
    });

    test('AppException 時把訊息帶到 errorMessage', () async {
      final repository = FakeAuthRepository(
        signInError: const AppException.server('帳號或密碼錯誤'),
      );
      final container = buildContainer(repository);
      addTearDown(container.dispose);
      await container
          .read(loginControllerProvider.notifier)
          .signIn(email: 'a@b.com', password: 'wrong');
      final state = container.read(loginControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, '帳號或密碼錯誤');
    });

    test('非預期例外時顯示通用錯誤訊息', () async {
      final repository = FakeAuthRepository(signInError: Exception('boom'));
      final container = buildContainer(repository);
      addTearDown(container.dispose);
      await container
          .read(loginControllerProvider.notifier)
          .signIn(email: 'a@b.com', password: '123456');
      final state = container.read(loginControllerProvider);
      expect(state.errorMessage, '登入失敗，請稍後再試');
    });
  });

  group('signUp', () {
    test('已直接取得 session 時 needsEmailConfirmation=false', () async {
      final repository = FakeAuthRepository();
      final container = buildContainer(repository);
      addTearDown(container.dispose);
      await container
          .read(loginControllerProvider.notifier)
          .signUp(email: 'a@b.com', password: '123456');
      final state = container.read(loginControllerProvider);
      expect(state.isSuccess, isTrue);
      expect(state.needsEmailConfirmation, isFalse);
      expect(repository.signUpCallCount, 1);
    });

    test('尚未取得 session（需要 Email 驗證）時 needsEmailConfirmation=true', () async {
      final repository = FakeAuthRepository(signUpResult: false);
      final container = buildContainer(repository);
      addTearDown(container.dispose);
      await container
          .read(loginControllerProvider.notifier)
          .signUp(email: 'a@b.com', password: '123456');
      final state = container.read(loginControllerProvider);
      expect(state.isSuccess, isTrue);
      expect(state.needsEmailConfirmation, isTrue);
    });

    test('AppException 時把訊息帶到 errorMessage', () async {
      final repository = FakeAuthRepository(
        signUpError: const AppException.server('此信箱已被註冊'),
      );
      final container = buildContainer(repository);
      addTearDown(container.dispose);
      await container
          .read(loginControllerProvider.notifier)
          .signUp(email: 'a@b.com', password: '123456');
      final state = container.read(loginControllerProvider);
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, '此信箱已被註冊');
    });
  });

  group('stale success flags', () {
    test('註冊成功後若下一次登入失敗，會清掉舊的 isSuccess / needsEmailConfirmation', () async {
      final repository = FakeAuthRepository(signUpResult: false);
      final container = buildContainer(repository);
      addTearDown(container.dispose);
      final notifier = container.read(loginControllerProvider.notifier);
      await notifier.signUp(email: 'a@b.com', password: '123456');
      var state = container.read(loginControllerProvider);
      expect(state.isSuccess, isTrue);
      expect(state.needsEmailConfirmation, isTrue);
      repository.signInError = const AppException.server('帳號或密碼錯誤');
      await notifier.signIn(email: 'a@b.com', password: 'wrong');
      state = container.read(loginControllerProvider);
      expect(state.isSuccess, isFalse);
      expect(state.needsEmailConfirmation, isFalse);
      expect(state.errorMessage, '帳號或密碼錯誤');
    });
  });
}
