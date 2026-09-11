import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/entities/app_user.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_travel_audio_guide/features/profile/di/profile_providers.dart';
import 'package:flutter_travel_audio_guide/features/profile/domain/entities/profile.dart';
import 'package:flutter_travel_audio_guide/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_travel_audio_guide/features/profile/presentation/controllers/profile_controller.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(
    this._controller, {
    bool initialIsSignedIn = false,
    String initialUserId = 'user-a',
  }) : currentUser = initialIsSignedIn
           ? AppUser(id: initialUserId, email: '$initialUserId@b.com')
           : null;

  final StreamController<bool> _controller;

  @override
  AppUser? currentUser;

  @override
  bool get isSignedIn => currentUser != null;

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

  void signInAs(String userId) {
    currentUser = AppUser(id: userId, email: '$userId@b.com');
    _controller.add(true);
  }

  void signOutUser() {
    currentUser = null;
    _controller.add(false);
  }
}

Profile buildProfile({
  String id = 'user-a',
  String displayName = 'Sun',
}) {
  final now = DateTime(2026);
  return Profile(
    id: id,
    email: '$id@b.com',
    displayName: displayName,
    preferredLanguage: 'zh-TW',
    createdAt: now,
    updatedAt: now,
  );
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.getMeResult});

  Profile? getMeResult;
  int getMeCallCount = 0;
  int updateMeCallCount = 0;
  bool useManualGetMeGates = false;
  bool useManualUpdateGates = false;
  final List<Completer<Profile>> getMeCompleters = [];
  final List<Completer<Profile>> updateCompleters = [];
  final List<Object> updateMeResults = [];

  @override
  Future<Profile> getMe() {
    getMeCallCount++;
    if (useManualGetMeGates) {
      final completer = Completer<Profile>();
      getMeCompleters.add(completer);
      return completer.future;
    }
    return Future.value(getMeResult ?? buildProfile());
  }

  @override
  Future<Profile> updateMe({
    String? displayName,
    String? avatarUrl,
    String? preferredLanguage,
  }) {
    updateMeCallCount++;
    if (useManualUpdateGates) {
      final completer = Completer<Profile>();
      updateCompleters.add(completer);
      return completer.future;
    }
    final result = updateMeResults[updateMeCallCount - 1];
    if (result is Exception) {
      return Future.error(result);
    }
    return Future.value(result as Profile);
  }
}

void main() {
  late StreamController<bool> authController;
  late FakeAuthRepository authRepository;
  late FakeProfileRepository profileRepository;
  late ProviderContainer container;

  ProviderContainer buildContainer({
    bool initialIsSignedIn = false,
    String initialUserId = 'user-a',
  }) {
    authController = StreamController<bool>();
    authRepository = FakeAuthRepository(
      authController,
      initialIsSignedIn: initialIsSignedIn,
      initialUserId: initialUserId,
    );
    return ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        profileRepositoryProvider.overrideWithValue(profileRepository),
      ],
    );
  }

  tearDown(() async {
    container.dispose();
    await authController.close();
  });

  test('初始已登入時自動呼叫 getMe() 取得 profile', () async {
    profileRepository = FakeProfileRepository(
      getMeResult: buildProfile(displayName: 'Sun2'),
    );
    container = buildContainer(initialIsSignedIn: true);
    container.listen(authStateChangesProvider, (_, _) {});
    container.listen(profileControllerProvider, (_, _) {});
    final profile = await container.read(profileControllerProvider.future);
    expect(profile?.displayName, 'Sun2');
    expect(profileRepository.getMeCallCount, 1);
  });

  test('未登入時不會呼叫 getMe()，state 為 null', () async {
    profileRepository = FakeProfileRepository();
    container = buildContainer();
    container.listen(authStateChangesProvider, (_, _) {});
    container.listen(profileControllerProvider, (_, _) {});
    final profile = await container.read(profileControllerProvider.future);
    expect(profile, isNull);
    expect(profileRepository.getMeCallCount, 0);
  });

  test('從未登入切換為登入時，會自動呼叫 getMe()', () async {
    profileRepository = FakeProfileRepository(
      getMeResult: buildProfile(id: 'user-b', displayName: 'Sun2'),
    );
    container = buildContainer();
    container.listen(authStateChangesProvider, (_, _) {});
    container.listen(profileControllerProvider, (_, _) {});
    expect(await container.read(profileControllerProvider.future), isNull);
    expect(profileRepository.getMeCallCount, 0);
    authRepository.signInAs('user-b');
    await Future<void>.delayed(Duration.zero);
    final profile = await container.read(profileControllerProvider.future);
    expect(profile?.displayName, 'Sun2');
    expect(profileRepository.getMeCallCount, 1);
  });

  test('updateProfile 成功時 state 更新為最新資料', () async {
    profileRepository = FakeProfileRepository(getMeResult: buildProfile())
      ..updateMeResults.add(buildProfile(displayName: 'Sun2'));
    container = buildContainer(initialIsSignedIn: true);
    container.listen(authStateChangesProvider, (_, _) {});
    container.listen(profileControllerProvider, (_, _) {});
    await container.read(profileControllerProvider.future);
    await container
        .read(profileControllerProvider.notifier)
        .updateProfile(displayName: 'Sun2');
    final state = container.read(profileControllerProvider);
    expect(state.value?.displayName, 'Sun2');
    expect(state.hasError, isFalse);
  });

  test('updateProfile 失敗時，state 保留錯誤，不會被吞掉換成舊資料', () async {
    profileRepository = FakeProfileRepository(getMeResult: buildProfile())
      ..updateMeResults.add(Exception('update failed'));
    container = buildContainer(initialIsSignedIn: true);
    container.listen(authStateChangesProvider, (_, _) {});
    container.listen(profileControllerProvider, (_, _) {});
    await container.read(profileControllerProvider.future);
    await container
        .read(profileControllerProvider.notifier)
        .updateProfile(displayName: 'Sun2');
    container.listen(authStateChangesProvider, (_, _) {});
    container.listen(profileControllerProvider, (_, _) {});
    expect(container.read(profileControllerProvider).hasError, isTrue);
  });

  test('較舊的 updateProfile 回應晚到時，不會蓋掉較新的結果', () async {
    profileRepository = FakeProfileRepository(getMeResult: buildProfile())
      ..useManualUpdateGates = true;
    container = buildContainer(initialIsSignedIn: true);
    container.listen(authStateChangesProvider, (_, _) {});
    container.listen(profileControllerProvider, (_, _) {});
    await container.read(profileControllerProvider.future);
    final notifier = container.read(profileControllerProvider.notifier);
    final firstUpdate = notifier.updateProfile(displayName: 'Old');
    await Future<void>.delayed(Duration.zero);
    final secondUpdate = notifier.updateProfile(displayName: 'New');
    await Future<void>.delayed(Duration.zero);
    expect(profileRepository.updateCompleters.length, 2);
    profileRepository.updateCompleters[1].complete(
      buildProfile(displayName: 'New'),
    );
    await secondUpdate;
    profileRepository.updateCompleters[0].complete(
      buildProfile(displayName: 'Old'),
    );
    await firstUpdate;
    expect(container.read(profileControllerProvider).value?.displayName, 'New');
  });

  test('refresh 成功時更新 state', () async {
    profileRepository = FakeProfileRepository(
      getMeResult: buildProfile(displayName: 'A'),
    );
    container = buildContainer(initialIsSignedIn: true);
    container.listen(authStateChangesProvider, (_, _) {});
    container.listen(profileControllerProvider, (_, _) {});
    await container.read(profileControllerProvider.future);
    profileRepository.getMeResult = buildProfile(displayName: 'B');
    await container.read(profileControllerProvider.notifier).refresh();
    expect(container.read(profileControllerProvider).value?.displayName, 'B');
  });

  test('未登入時呼叫 refresh 會把 state 清成 null，且不打 API', () async {
    profileRepository = FakeProfileRepository();
    container = buildContainer();
    container.listen(authStateChangesProvider, (_, _) {});
    container.listen(profileControllerProvider, (_, _) {});
    await container.read(profileControllerProvider.future);
    await container.read(profileControllerProvider.notifier).refresh();
    expect(container.read(profileControllerProvider).value, isNull);
    expect(profileRepository.getMeCallCount, 0);
  });

  test('A 的 refresh 晚到時，不可蓋掉已登入的 B profile', () async {
    profileRepository = FakeProfileRepository()..useManualGetMeGates = true;
    container = buildContainer(
      initialIsSignedIn: true,
    );
    // AsyncNotifier.build() is lazy. Reading the provider is what starts getMe().
    container.listen(authStateChangesProvider, (_, _) {});
    container.listen(profileControllerProvider, (_, _) {});
    final firstLoad = container.read(profileControllerProvider.future);
    await Future<void>.delayed(Duration.zero);
    expect(profileRepository.getMeCompleters, hasLength(1));
    profileRepository.getMeCompleters[0].complete(
      buildProfile(displayName: 'A'),
    );
    expect((await firstLoad)?.id, 'user-a');
    container.listen(profileControllerProvider, (_, _) {});
    final refreshFuture = container
        .read(profileControllerProvider.notifier)
        .refresh();
    await Future<void>.delayed(Duration.zero);
    expect(profileRepository.getMeCompleters, hasLength(2));
    authRepository.signOutUser();
    await Future<void>.delayed(Duration.zero);
    authRepository.signInAs('user-b');
    await Future<void>.delayed(Duration.zero);
    expect(profileRepository.getMeCompleters, hasLength(3));
    // Late A refresh must be dropped.
    profileRepository.getMeCompleters[1].complete(
      buildProfile(displayName: 'A-stale'),
    );
    await refreshFuture;
    profileRepository.getMeCompleters[2].complete(
      buildProfile(id: 'user-b', displayName: 'B'),
    );
    expect(
      (await container.read(profileControllerProvider.future))?.id,
      'user-b',
    );
    expect(
      container.read(profileControllerProvider).value?.displayName,
      'B',
    );
  });
}
